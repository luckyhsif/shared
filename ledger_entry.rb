class LedgerEntry < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :currency
  validates_numericality_of :credit, greater_than_or_equal_to: 0
  validates_numericality_of :debit, greater_than_or_equal_to: 0
  belongs_to :interaction
  
  validate :one_of_credit_or_debit
  
  protected
  
  def one_of_credit_or_debit
    if self.credit != 0 && self.debit != 0
      errors.add(:credit, "You can't assign both a credit and debit to the one entry.")
    end
  end
end
