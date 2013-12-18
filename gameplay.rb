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

class Gameplay < ActiveRecord::Base
  validates_presence_of :game
  validates_presence_of :user
  validates_presence_of :session_start
  validates_presence_of :session_end
  validate :session_end_after_start
  belongs_to :game
  belongs_to :user
  # t.text :report
  
  protected
  
  def session_end_after_start
    unless self.session_start < session_end
      errors.add(:session_end, "The session end must be after the session start.")
    end
  end
end
