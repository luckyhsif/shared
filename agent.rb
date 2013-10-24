require_relative 'user'

class Agent < User
  has_many :locations, inverse_of: :agent
  has_many :employees, foreign_key: :employer_id
  validate :has_a_location, :may_not_have_same_location

  def issue_bonus(player, amount, currency = Account::DEFAULT_CURRENCY)
    # who is requesting the action? employees or agents and do they have permission to
    # issue a bonus to a player?
    note = "Issued Bonus of #{currency} #{amount}"
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, currency)
      plr_acc = player.account(:wallet, currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: plr_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end

  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "Agent must have at least one Location.")
    end
  end

  def may_not_have_same_location
    agnt_id = self.locations.last 
      if agnt_id.agent_id != self.id 
        errors.add(:location, "Shares the same location as another Agent")
      end
  end

end
