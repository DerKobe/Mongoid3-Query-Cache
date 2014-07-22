Mongoid3-Query-Cache [![Build Status](https://travis-ci.org/DerKobe/Mongoid3-Query-Cache.svg?branch=master)](https://travis-ci.org/DerKobe/Mongoid3-Query-Cache)
====================

Backport of the Mongoid 4 QueryCache for Mongoid 3.

====================

The "port" is more of a copy-paste from Mongoid 4 (https://github.com/mongoid/mongoid). With very little effort I was able to use it with Mongoid 3.1.6.
For now it seems to work very good. 

I ported the original tests but had to build another mechanism for tracking calls to the database.

Due to changes from Moped 1.5 to 2.0 ```where``` calls are not cached like they are supposed to. I xit'ed the test for that but if anyone has an idea how to get this to work again, please feel free to submit a pull request.

Any other ideas and suggestion are very welcome, too of course!

Another tip: do not use Mongoid's IdentityMap! We ran into nasty problems with it. The QueryCache eases the pain of the missing caching effect of the IM ... and it's even better :-)

====================

##### Rails 3 usage
Add to your ```Gemfile```:
```ruby
gem 'mongoid-query_cache'
```

##### Rails 4 usage
Just use Mongoid 4 ... duh!

##### Other Rack-Apps
The preferred method is with bundler. Simply add the gem to your ```Gemfile```
```ruby
gem 'mongoid-query_cache'
```
and use the provided middleware
```ruby
use Mongoid::QueryCache::Middleware
```
