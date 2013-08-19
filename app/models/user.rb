#!/user/bin/env ruby
#coding: utf-8

# some notes that have helped me debug active_record stuff in the past
#
# declaration order counts.
# http://pivotallabs.com/activerecord-callbacks-autosave-before-this-and-that-etc/
#
# never end a callback with a false.
# http://blog.danielparnell.com/?p=20
# Case Insentitive searches in Postgres use ILIKE
# http://stackoverflow.com/questions/5052051/not-case-sensitive-search-with-active-record

class User < ActiveRecord::Base
  validates_presence_of :username
  validates_presence_of :password_hash

  def authenticate(clear_text_password)
    return password == clear_text_password
  end

  include BCrypt
  def password
    @password ||= Password.new(password_hash) # using bcrypt
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end
end
