#!/user/bin/env ruby
#coding: utf-8

# some notes that have helped me debug active_record stuff in the past
#
# declaration order counts.
# http://pivotallabs.com/activerecord-callbacks-autosave-before-this-and-that-etc/
#
# never end a callback with a false.
# http://blog.danielparnell.com/?p=20
# Case Insensitive searches in Postgres use ILIKE
# http://stackoverflow.com/questions/5052051/not-case-sensitive-search-with-active-record

class Credential < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :username
  validates_presence_of :token
  # remote
  belongs_to :user
  
  before_validation :generate_token, :reset_username
  
  protected
  
  require 'securerandom'

  def generate_token
    return if self.token
    tok = SecureRandom.urlsafe_base64(14).gsub(/[-|_]/,'')
    generate_token unless Credential.find_by_token(tok).nil?
    self.token = tok
  end

  def reset_username
    if self.username.nil? || self.username.empty?
      self.username = self.user.email.downcase.gsub(/[@|\.]/, '0')
    end
  end
end