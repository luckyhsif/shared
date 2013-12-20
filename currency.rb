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

# Currency.create(iso_code: 'ALL', name: 'Lek', fractional_unit: 'Qindarkë', number_to_basic: 100, symbol: 'L')
class Currency < ActiveRecord::Base
  
  @@DEFAULT = nil
  
  DEFAULTS = {
      iso_code: 'USD',
      name: 'Dollar',
      symbol: '$',
      fractional_unit: 'Cent'
  }
  
  validates_uniqueness_of :iso_code
  validates_presence_of :name
  validates_presence_of :symbol, allow_blank: true, default: ''
  validates_presence_of :iso_code
  validates_presence_of :fractional_unit
  has_many :ledger_entries
  has_many :countries
  has_many :accounts
  has_many :users

  def to_base(an_amount)
    raise ArgumentError, "an_amount must not be nil" if an_amount.nil?
    return (an_amount * self.number_to_basic).to_i  unless an_amount.is_a?(Integer)
    return an_amount
  end

  def to_whole(an_amount)
    raise ArgumentError, "an_amount must not be nil" if an_amount.nil?
    return an_amount.to_f / self.number_to_basic if an_amount.is_a?(Integer)
    return an_amount
  end

  def significant_digits
    return Math.log10(self.number_to_basic).to_i
  end

  def to_raw_string(an_amount = nil)
    return "%.#{significant_digits}f" % to_whole(an_amount)
  end
  
  def to_string(an_amount = nil)
    return an_amount.nil? ? "#{symbol_or_code}" : "#{symbol_or_code} #{to_raw_string(an_amount)}"
  end

  def to_formal_string(an_amount = nil)
    return an_amount.nil? ? "#{self.iso_code}" : "#{self.iso_code} #{to_raw_string(an_amount)}"
  end

  alias :to_s :to_string
  alias :to_sf :to_formal_string
  
  def self.default
    @@DEFAULT = Currency.where(iso_code: DEFAULTS[:iso_code]).first_or_create(DEFAULTS)
  end

  def self.default!
    @@DEFAULT = Currency.where(iso_code: DEFAULTS[:iso_code]).first_or_create!(DEFAULTS)
  end
  
  def symbol_or_code
    return self.symbol.empty? ? self.iso_code : self.symbol
  end
  
end
