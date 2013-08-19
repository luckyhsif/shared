#!/user/bin/env ruby
#coding: utf-8

require 'minitest_helper'
require './app/models/user'

describe User do
  include Rack::Test::Methods

  def app
    IGE_Core::Application
  end

  before :all do
    @user = User.create!(username: 'test', password: 'pass')
  end

  after :all do
    User.destroy_all
  end

  describe 'basic crud' do
    it 'the default user must authenticate properly' do
      User.transaction do
        @user.username.must_equal 'test'
        @user.authenticate('pass').must_equal true
      end
    end

    it 'must be able to find a user by username and authenticate them' do
      User.transaction do
        user = User.find_by_username('test')
        user.authenticate('pass').must_equal true
        user.must_equal @user
      end
    end
  end
end
