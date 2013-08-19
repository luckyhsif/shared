#!/user/bin/env ruby
#coding: utf-8
require 'rubygems'
require 'bundler/setup'
Bundler.setup
require 'rake/testtask'
require 'active_support/all'
require 'active_record'
require 'bcrypt'
require 'xml-sitemap'

Rake::TestTask.new( test: :'db:environment' ) do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
end

namespace :db do
  desc 'Set up environment variables'
  task :environment do
    require File.expand_path(File.join('config', 'database'), File.dirname(__FILE__))
  end

  desc "Migrate the database by walking through the migrations in db/migrate"
  task(:migrate => :environment) do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("./db/migrate", ENV["VERSION"] ? ENV[VERSION].to_i : nil)
  end

  desc 'Output the schema to db/schema.rb'
  task(:schema => :migrate) do
    File.open('./db/schema.rb', 'w') do |f|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, f)
    end
  end
  
  desc "Initialise the database by loading schema.rb file."
  task(:load => :environment) do
    schema_file = ENV['SCHEMA'] || File.join('./db', 'schema.rb')
    if File.exists?(schema_file)
      load(schema_file)
    else
      puts "WARNING -- NO SCHEME FILE FOUND OR SPECIFIED."
    end
  end

  desc 'Load the seed data from db/seeds.rb'
  task(:seed => :migrate) do
    raise "No models folder found." unless File.directory? './app/models'
    Dir.glob("./app/models/**.rb").sort.each { |m| require m }
    seed_file = File.join('./db', "#{ENV['RACK_ENV'] || 'development'}_seeds.rb")
    if File.exists?(seed_file)
      load(seed_file)
    else
      seed_file = File.join('./db', 'seeds.rb')
      if File.exists?(seed_file)
        load(seed_file)
      else
        puts "WARNING -- NO DATABASE SEED DATA FOUND."
      end
    end
  end

  desc 'Extract the seed data via db/extract.rb'
  task(:extract => :environment) do
    raise "No models folder found." unless File.directory? './app/models'
    Dir.glob("./app/models/**.rb").sort.each { |m| require m }
    extract_file = File.join('./db', "#{ENV['RACK_ENV'] || 'development'}_extract.rb")
    if File.exists?(extract_file)
      load(extract_file)
    else
      extract_file = File.join('./db', 'extract.rb')
      if File.exists?(extract_file)
        load(extract_file)
      else
        puts "WARNING -- NO DATABASE EXTRACTION RULES FOUND."
      end
    end
  end

end

@locales = %w(about products media careers contact site_map privacy terms)  # en is the default so no need for this.

def add_to_sitemap(map, path, priority = 0.8, updated = Date.today, period = :weekly)
  map.add(path, :priority => priority, :updated => updated, :period => period) unless path == '/'
  @locales.each do |loc|
    map.add("/#{loc}#{path}", :priority => priority, :updated => updated, :period => period)
  end
end

# see https://github.com/sosedoff/xml-sitemap for options.
desc 'render sitemap.xml file'
task :sitemap do
  map = XmlSitemap::Map.new('www.igecorporate.com') do |m|
    add_to_sitemap(m, '/')
  end
  map.render_to('./public/sitemap.xml')
end

desc 'Run tests'
task default: :test
