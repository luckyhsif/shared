class Account < ActiveRecord::Base
  DEFAULT_CURRENCY = 'EUR'

  belongs_to :owner, class_name: 'AdminUser'
  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:owner, :currency]
  has_many :ledger_entries, dependent: :destroy
  
  def balance
    credit = self.ledger_entries.sum(:credit)
    debit = self.ledger_entries.sum(:debit)
    return credit - debit
  end
  
  def empty?
    return self.ledger_entries.empty?
  end
end