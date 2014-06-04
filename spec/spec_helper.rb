# Configure Rails Environment
ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup

require 'mongoid'
require 'mongoid/query_cache'

Mongoid.load!(File.expand_path('../../spec/config/mongoid.yml', __FILE__))


RSpec.configure do |config|
  # some (optional) config here
end