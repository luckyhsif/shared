source 'https://rubygems.org'

ruby '2.0.0'

gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-r18n', require: 'sinatra/r18n'
gem 'sinatra-contrib'
gem 'sinatra-partial'
gem 'activerecord', '~>3.2.14', require: 'active_record'
gem 'activesupport', require: 'active_support/all'
gem 'therubyracer', require: 'v8'  # used for less
gem 'less'
gem 'slim'
gem 'thin'
gem 'sprockets'
gem 'rack-flash3', require: 'rack-flash'
gem 'bcrypt-ruby', require: 'bcrypt'
gem 'pg'
gem 'xml-sitemap' # see https://github.com/sosedoff/xml-sitemap

group :development, :test do
  gem 'rake'
end

group :development, :production do
  gem 'pony'
end

group :test do
  gem 'minitest', require: ['minitest/autorun', 'minitest/spec']
  gem 'rack-test', require: 'rack/test'
  gem 'simplecov', require: false
end
