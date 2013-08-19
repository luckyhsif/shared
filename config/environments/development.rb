#!/user/bin/env ruby
#coding: utf-8

IGE_Agent_Admin::Application.configure :development do |config|
  config.register Sinatra::Reloader

  # require 'thin'
  Thin::Logging.debug = true

end
