module Mongoid::QueryCache
  class Railtie < Rails::Railtie
    initializer 'mongoid.query_cache.insert_middleware' do |app|
      app.config.middleware.use 'Mongoid::QueryCache::Middleware'
    end
  end
end
