class User < ActiveRecord::Base
  
  has_and_belongs_to_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :messages, foreign_key: :sender_id
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy
  validates_presence_of :password_hash
  validates_presence_of :name
  validates_presence_of :email
  validates_uniqueness_of :email



 # include BCrypt
  def password
    @password ||= BCrypt::Password.new(password_hash) # using bcrypt
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_hash = @password
  end

  def authenticate(clear_text_password)
    return password == clear_text_password
  end

  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  def balance(name, currency = Account::DEFAULT_CURRENCY)
    return account(name, currency).balance
  end

  def is_allowed?(perm_name)
    p = Permission.find_by_name(perm_name)
    return false if p.nil?
    # huh? http://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-include-3F
    # TODO: find out why this is returning a '1' or nil, not true or false.
    return !self.permissions.include?(p).nil?
  end

end


# class Player < User
#   belongs_to :location
#   validates_presence_of :location

#   def deposit_cash(amount, currency = Account::DEFAULT_CURRENCY)
#     # who is requesting the action? employees or agents and do they have permission to
#     # let the player deposit cash?
#     agent = self.location.agent
#     note = 'cash deposit'
#     Interaction.transaction do |t|
#       my_acc = self.account(:cash, currency)
#       agt_acc = agent.account(:cash, currency)
#       entries = []
#       entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
#       entries << LedgerEntry.create!(account: agt_acc, credit: amount, currency: currency, note: note)
#       my_acc = self.account(:wallet, currency)
#       agt_acc = agent.account(:wallet, currency)
#       entries << LedgerEntry.create!(account: agt_acc, debit: amount, currency: currency, note: note)
#       entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
#       Interaction.create!(note: note, entries: entries)
#     end
#   end

#   def withdraw_cash(amount, currency = Account::DEFAULT_CURRENCY)
#     # who is requesting the action? employees or agents and do they have permission to
#     # let the player withdraw cash?
#     agent = self.location.agent
#     note = 'cash withdrawal'
#     Interaction.transaction do |t|
#       my_acc = self.account(:cash, currency)
#       agt_acc = agent.account(:cash, currency)
#       entries = []
#       entries << LedgerEntry.create!(account: agt_acc, debit: amount, currency: currency, note: note)
#       entries << LedgerEntry.create!(account: my_acc, credit: amount, currency: currency, note: note)
#       my_acc = self.account(:wallet, currency)
#       agt_acc = agent.account(:wallet, currency)
#       entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
#       entries << LedgerEntry.create!(account: agt_acc, credit: amount, currency: currency, note: note)
#       Interaction.create!(note: note, entries: entries)
#     end
#   end
# end

# class Employee < User
#   belongs_to :location
#   belongs_to :employer, class_name: 'Agent'
  
#   validates_presence_of :location
#   before_validation :assign_employer
  
#   protected
  
#   def assign_employer
#     if self.location.agent.nil?
#       errors.add(:location, "An Employee's Location must have an Agent.")
#     else
#       self.employer = self.location.agent if self.employer.nil?
#     end
#   end
# end

# class Agent < User
#   belongs_to :location
#   validates_presence_of :location
#   has_many :employees, foreign_key: :employer_id

#   def issue_bonus(player, amount, currency = Account::DEFAULT_CURRENCY)
#     # who is requesting the action? employees or agents and do they have permission to
#     # issue a bonus to a player?
#     note = "Issued Bonus of #{currency} #{amount}"
#     Interaction.transaction do |t|
#       my_acc = self.account(:wallet, currency)
#       plr_acc = player.account(:wallet, currency)
#       entries = []
#       entries << LedgerEntry.create!(account: my_acc, debit: amount, currency: currency, note: note)
#       entries << LedgerEntry.create!(account: plr_acc, credit: amount, currency: currency, note: note)
#       Interaction.create!(note: note, entries: entries)
#     end
#   end
# end

# class RegionalDistributor < User
#   has_many :locations, inverse_of: :regional_distributor
#   validate :has_a_location
#   protected
#   def has_a_location
#     if self.locations.empty?
#       errors.add(:location, "RegionalDistributor must have at least one Location.")
#     end
#   end
# end

# class MasterDistributor < User
#   has_many :locations, inverse_of: :master_distributor
#   validate :has_a_location
#   protected
#   def has_a_location
#     if self.locations.empty?
#       errors.add(:location, "MasterDistributor must have at least one Location.")
#     end
#   end
# end

# class CountryDistributor < User
#   has_many :locations, inverse_of: :country_distributor
#   validate :has_a_location
#   protected
#   def has_a_location
#     if self.locations.empty?
#       errors.add(:location, "CountryDistributor must have at least one Location.")
#     end
#   end
# end
