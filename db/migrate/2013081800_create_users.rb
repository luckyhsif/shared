#!/user/bin/env ruby
#coding: utf-8

class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :username, :null => false, :limit => 50
      t.string  :password_hash, :null => false, :limit => 100
      t.timestamps
    end
    add_index :users, :username, :unique => true
  end
  
  def self.down
    drop_table :users
  end
end
