require_relative 'user'

class Player < User
  belongs_to :venue
  validates_presence_of :venue
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy

  def self.list(offset=0, limit=0)
    total = self.all.count
    calculated_offset = offset * limit
    sqlstr = "SELECT P.* FROM users P" \
      " WHERE P.type = 'Player'" \
      " ORDER BY P.name LIMIT #{limit} OFFSET #{calculated_offset}"
    players = User.find_by_sql [sqlstr]
    # players = Player.all.order_by(:name).limit(limit).offset(calculated_offset)
    results = [players, total]
  end
 
  def agent
    return self.venue.agent
  end

  def may_have_venue?(venue)
    return self.agent_venues.include?(venue)
  end

  def balance_formatted
    return self.currency.to_s(self.balance)
  end

  def amount_formatted(amount)
    return self.currency.to_s(amount)
  end

  def account(name, currency = Currency.default)
    return self.accounts.where(name: name.to_s, currency: currency).first_or_create
  end

  # TODO: balance should be self.account(:wallet).balance + self.account(:gaming).balance
  def balance(name = 'wallet', currency = Currency.default)
    return account(name, currency).balance
  end

  def buy_into_network_game(amount, game)
    puts "todo"
  end

  def cash_out_from_network_game(amount, game)
    puts "todo"
  end

  def deposit_cash(amount, opts = {})
    raise ArgumentError, "Expected an integer amount" unless amount.is_a? Integer
    raise ArgumentError, "Expected an reference" if opts[:reference].nil?
    raise ArgumentError, "Expected the reference to be a TxId" unless opts[:reference].is_a? TxId
    note = 'cash deposit'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, self.currency)
      v_acc = venue.account(:cash, self.currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: self.currency, note: note)
      my_acc = self.account(:wallet, currency)
      v_acc = self.venue.account(:wallet, currency)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end

  def withdraw_cash(amount, opts = {})
    raise ArgumentError, "Expected an integer amount" unless amount.is_a? Integer
    raise ArgumentError, "Expected an reference" if opts[:reference].nil?
    raise ArgumentError, "Expected the reference to be a TxId" unless opts[:reference].is_a? TxId
    note = 'cash withdrawal'
    Interaction.transaction do |t|
      my_acc = self.account(:cash, currency)
      v_acc = self.venue.account(:cash, currency)
      entries = []
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: self.currency, note: note)
      my_acc = self.account(:wallet, currency)
      v_acc = self.venue.account(:wallet, currency)
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end

  def places_bet(amount, opts = {})
    note = 'player placed bet'
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, self.currency)
      v_acc = self.venue.account(:in_gaming, self.currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, credit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end

  def cancels_bet(amount, opts = {})
    note = 'player cancels bet'
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, self.currency)
      v_acc = self.venue.account(:in_gaming, self.currency)
      entries = []
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end
      
  def wins_game(amount, opts = {})
    note = 'player won game'
    Interaction.transaction do |t|
      my_acc = self.account(:wallet, self.currency)
      v_acc = self.venue.account(:wallet, self.currency)
      entries = []        
      entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end

  def deposit_test_money(amount, opts = {})
    note = 'player deposits test monet'
    Interaction.transaction do |t|
      pl_acc = self.account(:test, self.currency)
      v_acc = self.venue.account(:test, self.currency)
      entries = []        
      entries << LedgerEntry.create!(account: pl_acc, credit: amount, currency: self.currency, note: note)
      entries << LedgerEntry.create!(account: v_acc, debit: amount, currency: self.currency, note: note)
      Interaction.create!(note: note, entries: entries, reference: opts[:reference])
    end
  end

  def test_balance
    self.balance(:test)
  end

  private
  
  def check_accounting_opts!(opts)
    raise ArgumentError, "opts must be a hash" unless opts.is_a? Hash
    raise ArgumentError, "expected at least :reference as an option" if (opts.nil? || opts.empty?)
    raise ArgumentError, "expected :via to be a PaymentCard" if (!opts[:via].nil? && !opts[:via].is_a?(PaymentCard))
    raise ArgumentError, "expected a :reference" if opts[:reference].nil? || !opts[:reference].is_a?(TxId)
  end
    
  def assign_codes
    self.activation_code = unique_activation_code if self.activation_code.nil?
  end

  require 'securerandom'

  def unique_activation_code
    code = SecureRandom.urlsafe_base64
    code = unique_activation_code if User.exists?(:activation_code => code)
    return code
  end

end
