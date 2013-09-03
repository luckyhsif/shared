class Interaction < ActiveRecord::Base
  has_many :entries, class_name: 'LedgerEntry'
  validates_presence_of :note
  
  def balance
    credit = self.entries.sum(:credit)
    debit = self.entries.sum(:debit)
    return credit - debit
  end
  
end
