require_relative 'location'

class Venue < Location

  validates_presence_of :address
  has_many :accounts
  has_many :players
  validates_numericality_of :latitude, :greater_than_or_equal_to => -90.0, 
                                       :less_than_or_equal_to => 90.0, 
                                       :message => "Latitude must be between -90.0 and 90.0"
  validates_numericality_of :longitude, :greater_than_or_equal_to => -180.0, 
                                       :less_than_or_equal_to => 180.0, 
                                       :message => "Longitude must be between -180.0 and 180.0"
  validate :may_not_have_children
  
  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  def agent
    # Find the agent responsible for the current venue
    role = Role.find_by_name('Agent')
    #puts "\nVenue - agent, role: #{role.to_json}"
    rlist = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    agent = User.find_by_id(rlist.first.user_id)
    return agent
  end

  def has_employee?(employee) 
    role = Role.find_by_name('Employee')
    rlist = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    return rlist.count > 0
  end

  private
  
    def may_not_have_children
      #errors.add_to_base("A Venue may not have children") unless self.children.empty?
      errors[:base] << "A Venue may not have children" unless self.children.empty?
    end

end
