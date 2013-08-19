#!/user/bin/env ruby
#coding: utf-8

# see http://stackoverflow.com/questions/8717198/foreman-only-shows-line-with-started-wit-pid-and-nothing-else
$stdout.sync = true

require 'bundler'
require 'forwardable'

Bundler.require :default, ENV['RACK_ENV']

module IGE_Agent_Admin
  module Application
    # require the app helpers
    helpers = []
    helpers << app_help = File.join('app', 'helpers', 'application_helpers')
    require File.expand_path(app_help)

    # require the application controller
    app_con = File.join('app', 'controllers', 'application_controller')
    require File.expand_path(app_con)

    extend SingleForwardable
    def_single_delegators ApplicationController, :call, :configure, :new, :settings

    require File.expand_path(File.join('config', 'environment'))
    Dir[File.join('config', 'environments', '**/*.rb')].each { |file| require File.expand_path(file[0..-4]) }

    # require the rest of the helpers
    Dir[File.join('app', 'helpers', '**/*_helpers.rb')].each do |file|
      file = file[0..-4]
      # puts "DEBUGGING: helper = #{file.inspect} #{helpers.include?(file) ? 'already loaded' : ''}"
      require File.expand_path(file)
    end

    # require the rest of the controllers
    Dir[File.join('app', 'controllers', '**/*.rb')].each do |file|
      file = file[0..-4]
      # puts "DEBUGGING: controller = #{file.inspect} #{file == app_con ? 'already loaded' : ''}"
      require File.expand_path(file) unless file == app_con
    end

    # require the models
    Dir[File.join('app', 'models', '**/*.rb')].each { |file| require File.expand_path(file[0..-4]) }
  end
end
