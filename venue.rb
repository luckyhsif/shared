require_relative 'user'

class Venue < Location

  validates_presence_of :address
  has_many :accounts
  
  validate :may_not_have_children
  
  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  def employee   # To be revised
    role = Role.find_by_name('Employee')
    responsibility = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    employee = User.find_by_id(responsibility.first.user_id)
    return employee
  end

  def agent
    # Find the agent responsible for the current venue
    puts "\n Venue/agent"
    role = Role.find_by_name('Agent')
    puts "\n role: #{role.to_json}"
    rlist = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    agent = User.find_by_id(rlist.first.user_id)
    return agent
  end

  def is_managed_by?(user)
    # Is the current venue in the list of venues managed by the user
    # The user may be either an Employee or an Agent
    e_role = Role.find_by_name('Employee')
    a_role = Role.find_by_name('Agent')
    rlist = Responsibility.find_by_sql ["SELECT location_id FROM responsibilities r WHERE r.role_id = ? AND r.user_id = ?", e_role.id, user.id]
    rlist2 = Responsibility.find_by_sql ["SELECT location_id FROM responsibilities r WHERE r.role_id = ? AND r.user_id = ?", a_role.id, user.id]
    rlist.push(*rlist2)
    return nil if rlist.count == 0
    rlist.each do |r|
      return true if r.location_id == self.id
    end
    agent = self.agent
    puts "\n The agent for the current venue is #{agent.to_json}"
    # Now find out if the supplied user is a manager in the agent's management chain 
    false
  end

  private
  
    def may_not_have_children
      errors.add_to_base("A Venue may not have children") unless self.children.empty?
    end

end
