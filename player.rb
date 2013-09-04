class Player < User
  belongs_to :location
  validates_presence_of :location

  def deposit_cash(amount, currency = Account::DEFAULT_CURRENCY)
    # who is requesting the action? employees or agents and do they have permission to
    # let the player deposit cash?
    agent = self.location.agent
    note = 'cash deposit'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, currency)
      agt_acc = agent.account(:cash, currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: agt_acc, credit: amount, currency: currency, note: note)
      my_acc = self.account(:wallet, currency)
      agt_acc = agent.account(:wallet, currency)
      entries << LedgerEntry.create!(account: agt_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end

  def withdraw_cash(amount, currency = Account::DEFAULT_CURRENCY)
    # who is requesting the action? employees or agents and do they have permission to
    # let the player withdraw cash?
    agent = self.location.agent
    note = 'cash withdrawal'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, currency)
      agt_acc = agent.account(:cash, currency)
      entries = []
      entries << LedgerEntry.create!(account: agt_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
      my_acc = self.account(:wallet, currency)
      agt_acc = agent.account(:wallet, currency)
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: agt_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end
end
