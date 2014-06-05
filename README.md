Mongoid3-Query-Cache
====================

Backport of the Mongoid 4 QueryCache for Mongoid 3.

====================

The "port" is more of a copy-paste from Mongoid 4. With very little effort I was able to use it with Mongoid 3.1.6.
For now it seems to work very good. 

I left a lot of the original tests out because of missing functionality in Mongoid 3 that most of the tests depend on.

====================

The original can be found here: https://github.com/mongoid/mongoid

====================

##### Rails 3 usage
Add to your ```Gemfile```:
```ruby
gem 'mongoid-query_cache'
```

##### Rails 4 usage
Just use Mongoid 4 ... obviously.

##### Other Rack-Apps
The preferred method is with bundler. Simply add the gem to your ```Gemfile```
```ruby
gem 'mongoid-query_cache'
```
and use the provided middleware
```ruby
use Mongoid::QueryCache::Middleware
```
