class Interaction < ActiveRecord::Base
  has_many :entries, class_name: 'LedgerEntry'
  validates_presence_of :note

  validate :balance_must_be_zero

  # see http://stackoverflow.com/questions/18582085/objects-associated-collection-always-sums-to-0-during-validation-activerecord
  def balance
    credit = self.entries.to_a.map(&:credit).inject(&:+)
    debit = self.entries.to_a.map(&:debit).inject(&:+)
    return credit - debit
  end
  
  protected
  def balance_must_be_zero
    if self.balance != 0
      errors.add(:entries, "The entries must balance to zero.")
    end
  end
end
