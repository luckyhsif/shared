#!/user/bin/env ruby
#coding: utf-8

IGE_Agent_Admin::Application.configure do |config|
  # directory structure
  config.set :root, File.expand_path('../..', __FILE__)
  config.set :views, File.join(config.root, 'app', 'views')

  # R18n
  config.register Sinatra::R18n
  R18n::I18n.default = 'en'
  R18n.default_places { File.expand_path('locales', File.join(config.root, 'config')) }
  config.set :locales, R18n.available_locales.map {|loc| loc.code }
  config.set :locale_pattern, /^\/(#{Regexp.union(config.locales)})(\/.*)$/
  # see http://stackoverflow.com/questions/3104658/how-to-detect-language-from-url-in-sinatra

  # link header
  config.helpers Sinatra::LinkHeader

  # method override
  config.enable :method_override

  # partial
  config.register Sinatra::Partial
  config.set :partial_template_engine, :slim
  config.enable :partial_underscores

  # sessions
  #config.enable :sessions
  config.builder.use Rack::Session::Cookie,  :key => 'IGE_Key',
                                             :path => '/',
                                             :expire_after => 2592000,
                                             :secret => 'replace me or load from env' # TODO: load secret from env

  config.enable :protection
  config.builder.use Rack::Protection # see http://rkh.github.io/rack-protection/
  config.builder.use Rack::Flash, :accessorize => [:info, :success, :error]

  # show exceptions
  config.enable :show_exceptions

  # static files
  config.enable :static

  # template engine
  config.set :slim,
              layout_engine: :slim,
              layout: '../layouts/application'.to_sym,
              pretty: (config.environment == :development)

  require File.expand_path(File.join('config', 'database'))

end
