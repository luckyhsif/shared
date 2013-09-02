class Interaction < ActiveRecord::Base
  has_many :entries, class_name: 'LedgerEntry'
  validates_presence_of :note
  
  validate :entries_must_sum_to_zero
  
  def balance
    credit = self.entries.sum(:credit)
    debit = self.entries.sum(:debit)
    return credit - debit
  end
  
  protected
  
  def entries_must_sum_to_zero
    if self.entries.count.odd?
      errors.add(:entries, "There must be an even number of entries.")
    end
    if self.balance != 0
      errors.add(:entries, "Entries must sum to zero.")
    end
  end
end
