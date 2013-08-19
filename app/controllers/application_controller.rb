#!/user/bin/env ruby
#coding: utf-8

module IGE_Agent_Admin::Application
  class ApplicationController < Sinatra::Base
    set builder: Rack::Builder.new
    set controllers: []
    set project_root: File.expand_path('../..', root)
    set info: YAML.load(File.read(File.join(project_root, 'config', '/app-info.yml')))

    helpers IGE_Agent_Admin::Application::ApplicationHelpers

    def self.inherited(subclass)
      controllers << subclass unless controllers.include? subclass
      subclass.set :app_file, caller_files.detect { |f| f != app_file }
      super
    end

    def self.new(*)
      self == ApplicationController ? builder.to_app : super
    end

    def self.prefix=(value)
      controller = self
      define_singleton_method(:prefix) { value }
      builder.map(value) { run controller }
    end

    def self.views_prefix=(value)
      define_singleton_method(:views_prefix) { value }
    end

    def find_template(views, name, engine, &block)
      super(File.join(views, settings.views_prefix), name, engine, &block) if settings.respond_to? :views_prefix
      super(File.join(views, settings.prefix), name, engine, &block) if settings.respond_to? :prefix
      super(File.join(views, 'application'), name, engine, &block)
    end

    before do
      # filter out any locale info from the request path and
      # set the session locale accordingly.
      if request.path_info =~ settings.locale_pattern
        session[:locale], request.path_info = $1, $2
      elsif params[:locale]
        session[:locale] = params[:locale]
      end
    end

  end
end
