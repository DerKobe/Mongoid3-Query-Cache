# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/query_cache/version'

Gem::Specification.new do |spec|
  spec.name          = 'mongoid-query_cache'
  spec.version       = Mongoid::QueryCache::VERSION
  spec.authors       = ['Philip Claren']
  spec.email         = ['philip.claren@googlemail.com']
  spec.summary       = 'Backport of the Mongoid 4 QueryCache for Mongoid 3.'
  spec.description   = 'Backport of the Mongoid 4 QueryCache for Mongoid 3.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
