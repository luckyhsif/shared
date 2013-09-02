class LedgerEntry < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :currency
  validates_numericality_of :credit, :greater_than_or_equal_to => 0.0
  validates_numericality_of :debit, :greater_than_or_equal_to => 0.0
 
end
