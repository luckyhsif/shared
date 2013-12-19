require_relative 'user'

class Account < ActiveRecord::Base
  DEFAULT_CURRENCY = 'EUR'

  belongs_to :owner, class_name: 'Player'
  belongs_to :venue
  belongs_to :currency
  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:owner_id, :currency], if: :has_owner?
  validates_uniqueness_of :name, scope: [:venue_id, :currency], if: :has_venue?
  validates_presence_of :currency
  has_many :ledger_entries, dependent: :destroy
  
  validate :currency, :must_match_entries
  
  def balance
    credit = self.ledger_entries.sum(:credit)
    debit = self.ledger_entries.sum(:debit)
    return credit - debit
  end
  
  def empty?
    return self.ledger_entries.empty?
  end
  
  def self.casino(name = :wallet, currency = Currency.default)
    return Account.where("owner_id IS NULL").where(name: name.to_s, currency: currency).first_or_create(name: name.to_s, currency: currency, owner: nil)
  end

  def has_owner?
    return !self.owner.nil?
  end
  
  def has_venue?
    return !self.venue.nil?
  end
  private
  
  def must_match_entries
    # if cm = !self.currency.nil?
    #   puts "cm = !self.currency.nil?"
    # end
    # if self.ledger_entries.where("currency_id IS NOT ?", self.currency.id).count > 0
    #   puts "self.ledger_entries.where('currency_id IS NOT ?', self.currency.id).count > 0)"
    # end
    # if cm = !self.currency.nil? && (self.ledger_entries.where("currency_id IS NOT ?", self.currency.id).count > 0)
    #   errors.add(:currency,
    #     "There #{cm == 1 ? 'is' : 'are'} #{cm} ledger entr#{cm == 1 ? 'y' : 'ies'} out of #{self.ledger_entries.count} total")
    # end
  end

end
