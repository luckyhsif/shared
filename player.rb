require_relative 'user'

class Player < User
  belongs_to :venue
  validates_presence_of :venue
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy

  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  def balance(name, currency = Account::DEFAULT_CURRENCY)
    return account(name, currency).balance
  end

  def deposit_cash(amount, currency = Account::DEFAULT_CURRENCY)
    # who is requesting the action? employees or agents and do they have permission to
    # let the player deposit cash?
    venue = self.venue
    note = 'cash deposit'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, currency)
      v_acc = venue.account(:cash, currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: currency, note: note)
      my_acc = self.account(:wallet, currency)
      v_acc = venue.account(:wallet, currency)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end

  def withdraw_cash(amount, currency = Account::DEFAULT_CURRENCY)
    # who is requesting the action? employees or agents and do they have permission to
    # let the player withdraw cash?
    venue = self.venue
    note = 'cash withdrawal'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, currency)
      v_acc = venue.account(:cash, currency)
      entries = []
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
      my_acc = self.account(:wallet, currency)
      v_acc = venue.account(:wallet, currency)
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end
  
  def loses_game(amount, currency = Account::DEFAULT_CURRENCY)
    venue = self.venue
    note = 'player lost game'
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, currency)
      v_acc = venue.account(:wallet, currency)
      entries = []        
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end
    
  def wins_game(amount, currency = Account::DEFAULT_CURRENCY)
    venue = self.venue
    note = 'player won game'
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, currency)
      v_acc = venue.account(:wallet, currency)
      entries = []        
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: currency, note: note)
      Interaction.create!(note: note, entries: entries)
    end
  end

end
