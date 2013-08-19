#!/user/bin/env ruby
#coding: utf-8

require 'minitest_helper'

describe IGE_Agent_Admin::Application::ApplicationHelpers do
  include Rack::Test::Methods

  def app
    IGE_Agent_Admin::Application
  end
end
