require_relative 'user'

Class Venue < User

  validates_presence_of :address
  
  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

end