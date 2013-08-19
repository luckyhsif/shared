#!/user/bin/env ruby
#coding: utf-8
# see http://www.rubyinside.com/a-minitestspec-tutorial-elegant-spec-style-testing-that-comes-with-ruby-5354.html

require 'minitest_helper'

describe IGE_Agent_Admin::Application::RootController do
  include Rack::Test::Methods

  def app
    IGE_Agent_Admin::Application
  end

  describe 'basic page existence tests' do
    
    before :all do
      @nav = %w(/ /privacy /terms)
    end
    
    it 'must be ok and default to English' do
      @nav.each do |n|
        get n
        last_response.must_be :ok?
        last_response.body.must_match '<html lang="en">'
      end
    end
  end

end
