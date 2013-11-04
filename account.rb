require_relative 'user'

class Account < ActiveRecord::Base
  DEFAULT_CURRENCY = 'EUR'

  belongs_to :owner, class_name: 'Player'
  belongs_to :venue
  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:owner_id, :currency], if: :has_owner?
  validates_uniqueness_of :name, scope: [:venue_id, :currency], if: :has_venue?
  has_many :ledger_entries, dependent: :destroy
  
  def balance
    credit = self.ledger_entries.sum(:credit)
    debit = self.ledger_entries.sum(:debit)
    return credit - debit
  end
  
  def empty?
    return self.ledger_entries.empty?
  end
  
  def has_owner?
    return !self.owner.nil?
  end
  
  def has_venue?
    return !self.venue.nil?
  end
end
