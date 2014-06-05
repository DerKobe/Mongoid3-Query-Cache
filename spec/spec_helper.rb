ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup

require 'mongoid'
require 'mongoid/query_cache'
Mongoid.load!(File.expand_path('../../spec/config/mongoid.yml', __FILE__))

class MongoLogger < Logger
  attr_accessor :messages

  def initialize(*args)
    super *args
    self.messages = []
  end

  def add(severity, message = nil, progname = nil, &block)
    messages << progname
  end

  def count
    messages.count
  end
end
Moped.logger = MongoLogger.new(STDOUT)