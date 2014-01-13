class Interaction < ActiveRecord::Base
  has_many :entries, class_name: 'LedgerEntry'
  belongs_to :reference, class_name: 'TxId'
  validates_presence_of :note
  validates_presence_of :reference
  validates_uniqueness_of :reference
  # also has a 'remote' string property
  validate :balance_must_be_zero

  def amount
    return self.entries.to_a.map(&:credit).inject(&:+)
  end

  # see http://stackoverflow.com/questions/18582085/objects-associated-collection-always-sums-to-0-during-validation-activerecord
  def balance
    credit = self.amount
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

class Deposit < Interaction
  belongs_to :user
end

class Withdrawal < Interaction
  belongs_to :user
end

class Bet < Interaction
  belongs_to :user
end

class Winning < Interaction
  belongs_to :user
end

class Cancellation < Interaction
  belongs_to :user
end

class GameEnd < Interaction
  belongs_to :user
end

class AcceptedBonus < Interaction
  belongs_to :user
  belongs_to :bonus
  
  before_validation :bonus_is_accepted
  
  private
  
  def bonus_is_accepted
    return if self.bonus.nil?
    return if true == self.bonus.is_accepted
    self.bonus.accept!
    self.bonus.accepted_bonus = self
    self.bonus.save!
  end
end
