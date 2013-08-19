#!/user/bin/env ruby
#coding: utf-8

# checkout the MiniTest::Spec docs
# http://bfts.rubyforge.org/minitest/MiniTest/Spec.html

require "simplecov"
SimpleCov.start

ENV['RACK_ENV'] = 'test'

require File.expand_path(File.join('config', 'application'))
