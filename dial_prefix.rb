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

# DialPrefix.create(dial_code: '+61', country: australia)
class DialPrefix < ActiveRecord::Base
  validates_presence_of :dial_code
  belongs_to :country
end
