require 'mongoid/query_cache/version'
require 'mongoid/query_cache/railtie' if defined? Rails

module Mongoid

  # A cache of database queries on a per-request basis.
  #
  module QueryCache
    class << self

      # Get the cached queries.
      #
      # @example Get the cached queries from the current thread.
      #   QueryCache.cache_table
      #
      # @return [ Hash ] The hash of cached queries.
      #
      def cache_table
        Thread.current["[mongoid]:query_cache"] ||= {}
      end

      # Clear the query cache.
      #
      # @example Clear the cache.
      #   QueryCache.clear_cache
      #
      # @return [ nil ] Always nil.
      #
      def clear_cache
        Thread.current["[mongoid]:query_cache"] = nil
      end

      # Set whether the cache is enabled.
      #
      # @example Set if the cache is enabled.
      #   QueryCache.enabled = true
      #
      # @param [ true, false ] value The enabled value.
      #
      def enabled=(value)
        Thread.current["[mongoid]:query_cache:enabled"] = value
      end

      # Is the query cache enabled on the current thread?
      #
      # @example Is the query cache enabled?
      #   QueryCache.enabled?
      #
      # @return [ true, false ] If the cache is enabled.
      #
      def enabled?
        !!Thread.current["[mongoid]:query_cache:enabled"]
      end

      # Execute the block while using the query cache.
      #
      # @example Execute with the cache.
      #   QueryCache.cache { collection.find }
      #
      # @return [ Object ] The result of the block.
      #
      def cache
        enabled = QueryCache.enabled?
        QueryCache.enabled = true
        yield
      ensure
        QueryCache.enabled = enabled
      end
    end

    # The middleware to be added to a rack application in order to activate the
    # query cache.
    #
    class Middleware

      # Instantiate the middleware.
      #
      # @example Create the new middleware.
      #   Middleware.new(app)
      #
      # @param [ Object ] app The rack applciation stack.
      #
      def initialize(app)
        @app = app
      end

      # Execute the request, wrapping in a query cache.
      #
      # @example Execute the request.
      #   middleware.call(env)
      #
      # @param [ Object ] env The environment.
      #
      # @return [ Object ] The result of the call.
      #
      def call(env)
        QueryCache.cache { @app.call(env) }
      ensure
        QueryCache.clear_cache
      end
    end

    module Base # :nodoc:

      def alias_query_cache_clear(*method_names)
        method_names.each do |method_name|
          class_eval <<-CODE, __FILE__, __LINE__ + 1
              def #{method_name}_with_clear_cache(*args)   # def upsert_with_clear_cache(*args)
                QueryCache.clear_cache                     #   QueryCache.clear_cache
                #{method_name}_without_clear_cache(*args)  #   upsert_without_clear_cache(*args)
              end                                          # end
          CODE

          alias_method_chain method_name, :clear_cache
        end
      end
    end

    # Module to include in objects which need to wrap caching behaviour around
    # them.
    #
    module Cacheable

      private

      def with_cache(context = :cursor, &block)
        return yield unless QueryCache.enabled?
        return yield if system_collection?
        key = cache_key.push(context)

        if QueryCache.cache_table.has_key?(key)
          instrument(key) { QueryCache.cache_table[key] }
        else
          QueryCache.cache_table[key] = yield
        end
      end

      def instrument(key, &block)
        ActiveSupport::Notifications.instrument("query_cache.mongoid", key: key, &block)
      end
    end

    # Adds behaviour around caching to a Moped Query object.
    #
    module Query
      extend ActiveSupport::Concern
      include Cacheable

      included do
        extend QueryCache::Base
        alias_method_chain :cursor, :cache
        alias_method_chain :first, :cache
        alias_query_cache_clear :remove, :remove_all, :update, :update_all, :upsert
      end

      # Provide a wrapped query cache cursor.
      #
      # @example Get the wrapped caching cursor.
      #   query.cursor_with_cache
      #
      # @return [ CachedCursor ] The cached cursor.
      #
      def cursor_with_cache
        CachedCursor.new(session, operation)
      end

      # Override first with caching.
      #
      # @example Get the first with a cache.
      #   query.first_with_cache
      #
      # @return [ Hash ] The first document.
      #
      def first_with_cache
        with_cache(:first) do
          first_without_cache
        end
      end

      private

      def cache_key
        [ operation.database, operation.collection, operation.selector, operation.limit, operation.skip, operation.fields ]
      end

      def system_collection?
        operation.collection =~ /^system./
      end
    end

    # Adds behaviour to the query cache for collections.
    #
    module Collection
      extend ActiveSupport::Concern

      included do
        extend QueryCache::Base
        alias_query_cache_clear :insert
      end
    end

    # A Cursor that attempts to load documents from memory first before hitting
    # the database if the same query has already been executed.
    #
    class CachedCursor < Moped::Cursor
      include Cacheable

      # Override the loading of docs to attempt to fetch from the cache.
      #
      # @example Load the documents.
      #   cursor.load_docs
      #
      # @return [ Array<Hash> ] The documents.
      #
      def load_docs
        with_cache { super }
      end

      private

      def cache_key
        [ @database, @collection, @selector, @options[:limit], @options[:skip], @options[:fields] ]
      end

      def system_collection?
        @collection =~ /^system./
      end
    end
  end
end

Moped::Query.send(:include, Mongoid::QueryCache::Query)
Moped::Collection.send(:include, Mongoid::QueryCache::Collection)
