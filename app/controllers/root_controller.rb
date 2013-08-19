#!/user/bin/env ruby
#coding: utf-8

# Controller for all of the public areas of the site.
module IGE_Agent_Admin::Application
  class RootController < ApplicationController
    set prefix: '/'
    set views_prefix: '/root'

    helpers IGE_Agent_Admin::Application::RootHelpers
    helpers IGE_Agent_Admin::Application::EmailHelpers

    # page requests

    get '/' do
      @title = t.views.root.index.title
      slim :index, locals: {is_home: true}
    end

    get '/site_map' do
      @title = t.views.root.site_map.title
      slim :site_map
    end

    get '/privacy' do
      @title = t.views.root.privacy.title
      slim :privacy
    end

    get '/terms' do
      @title = t.views.root.terms.title
      slim :terms
    end

  end
end
