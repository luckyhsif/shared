require_relative 'user'

class Venue < Location

  validates_presence_of :address
  has_many :accounts
  
  validate :may_not_have_children
  
  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  private
  
  def may_not_have_children
    errors.add_to_base("A Venue may not have children") unless self.children.empty?
  end
end
