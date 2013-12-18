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

class TxId < ActiveRecord::Base
  # see http://drawohara.com/post/117643208/ruby-integer-max-and-integer-min
  MAX_TXID = 2 ** ([42].pack('i').size * 8 - 2) - 1

  validates_presence_of :txid
  validates_uniqueness_of :txid
  belongs_to :user
  has_one :interaction, foreign_key: :reference_id
  has_one :isb_log, class_name: 'ISoftbetLog', foreign_key: :txid_id

  validates_numericality_of :txid, only_integer: true, greater_than_or_equal_to: 0
  before_validation :generate_values
  
  protected
  
  require 'securerandom'
  
  def generate_values
    generate_token
    generate_label
  end
  
  def generate_token
    return if !self.txid.nil? && self.txid > 0
    tid = (1 + SecureRandom.random_number(MAX_TXID - 102))
    generate_token if TxId.exists?(txid: tid)
    self.txid = tid
  end
  
  def generate_label
    return unless self.label.nil?
    lab = SecureRandom.urlsafe_base64(5).downcase
    generate_label if TxId.exists?(label: lab)
    self.label = lab
  end
end
