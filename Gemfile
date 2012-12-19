source 'https://rubygems.org'

def jenkins?
  ENV['JENKINS'] == "true"
end

gem 'rails', '3.2.8'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
  gem 'therubyracer'
  gem 'compass-rails'
end

gem 'mongoid',        '~>2.0'
gem 'mongoid-tree',   '~> 0.7'
gem 'bson_ext'
gem 'haml-rails'
gem 'simple_form'
gem 'jquery-rails'
gem 'carrierwave-mongoid'
gem 'mini_magick'
gem 'kaminari'
gem 'nokogiri'
gem 'loofah'
gem 'redis'
gem 'devise'
gem 'state_machine'
gem 'smt_rails'
gem 'typhoeus'
gem 'faraday'
gem 'faraday_middleware'
gem 'hashie'
gem 'gaston'
gem 'responders'

gem 'thin'
gem 'sinatra'
gem 'resque', require: 'resque/server'
gem 'resque-pool',
  github: "spk/resque-pool",
  branch: "improve_tasks"

gem 'peregrin'

group :development do
  gem 'letter_opener'
  gem 'quiet_assets'
  gem 'mo'
  gem 'shotgun'
end

group :test do
  gem 'rspec-rails', '~>2.10.0'
  gem 'fabrication'
  gem 'resque_spec'
  gem 'mongoid-rspec', '1.4.4'
  gem 'simplecov', require: false
  gem 'ffaker'
  gem 'pry-rails'
  gem 'database_cleaner'
  gem 'fakeweb'
end

group :test, :development do
  gem 'jasmine', github: 'pivotal/jasmine-gem'
  gem 'guard-jasmine-headless-webkit'
  gem 'guard-rspec'
  gem 'guard-jasmine-headless-webkit'
  gem 'pry-rails',  jenkins? ? {require: false} : {}
end
