class User < ActiveRecord::Base

  has_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :responsibilities
  has_many :locations, through: :responsibilities
  has_many :messages, foreign_key: :sender_id
  has_many :userroles, foreign_key: :user_id
  has_many :roles, through: :userroles
  has_many :managers, through: :userroles, foreign_key: :manager_id

  email_regex = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i

  validates :email, :presence   => true,
                    :format     => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
  validates :name,  :presence   => true, 
                    :length     => { :maximum => 50 }
  validates_presence_of :password_hash

  LEVELS = [{count: 1, user_type: 'Player'},
            {count: 2, user_type: 'Employee'},
            {count: 3, user_type: 'Agent'},
            {count: 4, user_type: 'RegionalDistributor'},
            {count: 5, user_type: 'MasterDistributor'},
            {count: 6, user_type: 'CountryDistributor'},
            {count: 7, user_type: 'Staff'}]
          

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

  def available_permissions
    return self.permissions
  end

  def manager_for_role(role) 
    responsibilities = Responsibility.find_by_sql ["SELECT manager_id FROM responsibilities r WHERE r.role_id = ? AND r.user_id = ?", role.id, self.id]
    return nil if responsibilities.empty?
    manager = User.find_by_id(responsibilities.first.manager_id)
    return manager
  end

  def agent_of_employee
    employee_role_type = Role.find_by_name('Employee')
    rlist = Userrole.where("user_id=? AND role_id=?", self.id, employee_role_type.id)
    return nil if rlist.empty?
    agent = rlist.first.manager
    return nil if agent.nil?
    return agent
  end

  def is_employee?
    employee_role_type = Role.find_by_name('Employee')
    rlist = Responsibility.where("role_id=? AND user_id=?", employee_role_type, self)
    return rlist.count > 0
  end

  def is_agent? 
    agent_role_type = Role.find_by_name('Agent')
    rlist = Responsibility.where("role_id=? AND user_id=?", agent_role_type, self)
    return rlist.count > 0
  end

  def is_employee_at_venue?(venue)
    employee_role_type = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=? AND location_id=?", self.id, employee_role_type.id, venue.id)
    return rlist.count > 0
  end
  
  def agent_venues
    venues = []
    role = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, role.id)
    venues = Venue.find(rlist.map(&:location_id).uniq)
  end

  def employee_venues
    venues = []
    return venues unless self.is_employee?
    role = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, role.id)
    venues = Venue.find(rlist.map(&:location_id).uniq)
  end

  def agent_employees
    employees = []
    agent_role_type = Role.find_by_name('Agent')
    employee_role_type = Role.find_by_name('Employee')
    agent_roles = Userrole.where("role_id=? AND manager_id=?", employee_role_type.id, self.id)
    return employees if agent_roles.empty?
    agent_roles.each do |userrole|
      employees << userrole.user
    end
    return employees
  end

  def agent_players     #tested
    agent_role_type = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self, agent_role_type)
    players = []
    return players if rlist.empty?
    rlist.each do |r|
      venue = r.location
      players.push(*venue.players)
    end
    return players
  end

  def employee_players 
    employee_role_type = Role.find_by_name('Employee')
    players = []
    return players unless self.is_employee?
    venues = self.employee_venues
    return players if venues.empty?
    venues.each do |venue|
      players.push(*venue.players)
    end
    return players
  end

  def agent_of_player    # tested
    return nil unless self.type == 'Player'
    venue = self.venue
    agent_role_type = Role.find_by_name('Agent')
    rlist = Responsibility.where("role_id=? AND location_id=?", agent_role_type.id, venue.id)
    return nil if !rlist || rlist.count == 0
    agent = User.find_by_id(rlist.first.user)
    return agent
  end

  def manages_user?(user)   #tested
    subordinate = user
    manager = self
    return false if subordinate == manager
    return false if manager.active == false
    return false if manager.type == 'Player'
    return true if manager.type == 'Staff'
    manager_role = manager.most_senior_role
    if subordinate.type == 'Player'
      subordinate_role_name = 'Player'
    else
      subordinate_role = subordinate.most_senior_role
      subordinate_role_name = subordinate_role.name
    end
    # puts "manages_user?(user) - all roles"
    # puts "Manager: #{manager.name}" 
    # puts "manager role: #{manager_role.name}"
    # puts "Subordinate: #{subordinate.name}" 
    # puts "subordinate role_name: #{subordinate_role_name}"
    if manager_role.name == 'Employee' 
      return false unless subordinate_role_name == 'Player'
      return subordinate.venue.has_employee?(manager)
    end
    if manager_role.name == 'Agent'
      return manager.agent_venues.include?(subordinate.venue) if subordinate_role_name == 'Player'
      return manager.agent_employees.include?(subordinate) if subordinate_role_name == 'Employee'
      return false
    end
    if subordinate_role_name == 'Player'
      subordinate = subordinate.agent_of_player
    elsif subordinate_role_name == 'Employee'
      subordinate = subordinate.agent_of_employee
      return false if subordinate.nil?     # This will hapen if the test case does not include an employee role type
    end
    managers = subordinate.managers
    return managers.include?(manager)
  end


  # Determine the access level that self has for this child location
  def access_level_for_location(child_location)
    return 'NONE' if child_location.nil?
    return 'ALL' if self.is_a?(Staff)
    return 'NONE' if self.is_a?(Player)
    responsibilities = Responsibility.where("user_id=?", self.id)
    # If the query does no results, self has no responsibility for any location
    return 'NONE' if responsibilities.empty?
    child_location_parent_ids = child_location.parent_location_ids
    # Determine if self has a responsibility for one of its parent locations
    responsibilities.each do |resp|
      return 'ALL' if child_location_parent_ids.include?(resp.location.id)
    end
    responsibilities = Responsibility.where("user_id=? AND location_id=?", self.id, child_location.id)
    return responsibilities.empty? ? 'NONE' : 'VIEW'

    # puts responsibilities.to_json
    # roles = responsibilities.map{ |resp| resp.role.name }
    # case location.type
    # when 'MasterRegion'
    #   return 'ALL' if roles.include?('Country Distributor')
    #   return 'VIEW' if roles.include?('Master Distributor')
    #   return 'NONE'
    # when 'Region'
    #   return 'ALL' if roles.include?('Country Distributor') || roles.include?('Master Distributor')
    #   return 'VIEW' if roles.include?('Regional Distributor')
    #   return 'NONE'
    # when 'Venue'
    #   return 'ALL' if roles.include?('Country Distributor') || roles.include?('Master Distributor') || roles.include?('Regional Distributor')
    #   return 'VIEW' if roles.include?('Agent') || roles.include?('Employee') 
    # end
    # 'NONE'
  end

  def managers 
    managers = []
    if self.type == 'Player'
      subordinate = self
      venue = subordinate.venue
      agent_role_type = Role.find_by_name('Agent')
      rlist = Responsibility.where("role_id=? AND location_id=?", agent_role_type.id, venue.id)
      return nil if rlist.count == 0
      agent = User.find_by_id(rlist.first.user_id)
      return nil if agent == nil
      managers << agent
      subordinate = agent
    end
    rlist = Userrole.where("user_id=?", self.id)
    return managers if rlist.empty?
    rlist.each do |role|
      if role.manager != nil
        manager = User.find_by_id(role.manager_id)
        managers << manager
        managers.push(*manager.managers)
      end
    end
    return managers
  end

  def manager_of?(user)
    user.managers.include?(self)
  end

  def manager(location)
    # Returns the immediate manager of the current user
    #puts "Entering User - manager, self: #{self.to_json}"
    if self.type == 'Player'
      #role = Role.find_by_name('Agent')   # The role is derived from the responsibility
      responsibilities = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, location.id]
      # The specified location can have only one Agent
      # The agent is the manager of the current player
      manager = User.find_by_id(responsibilities.first.user_id)
    else  # It is a User
      puts "\n User - manager(loc) - It is a User"
      #responsibilities = Responsibility.find_by_sql ["SELECT id, role_id FROM responsibilities r WHERE r.user_id = ? AND r.location_id = ?", self.id, location.id]
      responsibilities = Responsibility.where("user_id=? AND location_id=?", self.id, location.id)
      # The current user will have one responsibility for these criteria
      responsibility = Responsibility.find_by_id(responsibilities.first.id)
      if !responsibility
        return nil
      end
      manager = responsibility.manager
    end
    return manager
  end

 # include BCrypt
  def password
    @password ||= BCrypt::Password.new(password_hash) # using bcrypt
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_hash = @password
  end

  def authenticate(clear_text_password)
    # puts "DEBUGGING: self.active = #{self.active}"
    # puts "DEBUGGING: passwords match = #{(password == clear_text_password)}"
    # puts "DEBUGGING: authenticated? #{self.active && (password == clear_text_password)}"
    return self.active && (password == clear_text_password)
  end

  def valid_password_change?(old_pw, nominated_pw, pw_confirmation)
    return false unless self.authenticate(old_pw)
    return false if old_pw == nominated_pw
    return nominated_pw == pw_confirmation
  end

  def location_summary(provider, location, rpt_from, rpt_end)
    # e.g. If provider is Sports, this method returns a revenue summary line  
    # for games recorded by Sports at <location> from <rpt_from> until
    # <rpt_end> for the user, <self>
  end  

  def location_games(provider, location, rpt_from, rpt_end)
    # e.g. If provider is Sports, this method returns the list of games  
    # recorded by Sports at <location> from <rpt_from> until
    # <rpt_end> for the user, <self> sorted in descending sequence
  end  

  def is_allowed?(perm_name)
    p = Permission.find_by_name(perm_name)
    return false if p.nil?
    # huh? http://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-include-3F
    # TODO: find out why this is returning a '1' or nil, not true or false.
    return !self.permissions.include?(p).nil?
  end

  def is_active?
    return self.active
  end

  def block
    self.active = false
  end

  def unblock
    self.active = true
    self.adjust_logons
  end

  def allocated_locations
    # returns the locations allocated directly to the current user
    return [] if self.type == 'Staff'
    locations = []
    if self.type == 'Player'
      locations << self.venue
      return locations
    end
    role = self.most_senior_role
    responsibilities = Responsibility.where("user_id=? AND role_id=?", self, role)
    return nil unless responsibilities
    responsibilities.each do |r|
      locations << r.location
    end
    return locations
  end
  
  def distributor_locations
    locations = []
    distributor = self
    role = distributor.most_senior_role
    rlist = Responsibility.where("user_id=? AND role_id=?", distributor, role)
    rlist.each do |r|
      loc = Location.find_by_id(r.location_id)
      locations.push(*loc.descendant_locations)
    end
    return locations
  end

  def included_locations    # This is tested but is not used yet
    immediate_locations = self.allocated_locations
    all_locations = []
    all_locations.push(*immediate_locations)
    immediate_locations.each do |l|
      dl = l.descendant_locations
      all_locations.push(*dl)
    end
    return all_locations
  end

  def most_senior_role  
    if self.class.name == 'Player'
      role = Role.find_by_name('Player')
      return role
    end
    if self.class.name == 'Staff'
      role = Role.find_by_name('Staff')
      return role
    end
    userroles = Userrole.where("user_id=?", self)
    return nil unless userroles.count > 0
    return userroles.first.role if userroles.count == 1
    roles = []
    userroles.each do |userrole|
      roles << userrole.role
    end
    highest_role = roles.max { |a,b| a.level <=> b.level}
    return highest_role
  end

  def immediate_subordinates
    urlist = Userrole.where("manager_id = ?", self)
    return nil unless urlist && urlist.count > 0
    users = User.find(urlist.map(&:user_id).uniq)
  end

  def is_subordinate_of?(user, location)    #  not used - still working on this
    subordinate = self
    puts "\n (1) is_subordinate_of? testing self: #{subordinate.to_json}"
    puts "\n (2) is_subordinate_of? testing manager: #{user.to_json}"
    if self.type == 'Player'
      puts "\n 1 is_subordinate_of, venue #{subordinate.venue.to_json}"
      manager = subordinate.venue.agent
    else
      puts "\n 2 is_subordinate_of location: #{location.to_json}"
      manager = subordinate.manager(location)
    end
    puts "\n self manager: #{manager.to_json}"      # Lisa Agent
    puts "\n manager: #{user.to_json}"              # Harry Employee
    while manager != nil
      return true if manager == user
      puts "\n manager != user"
      manager = manager.manager(location)
      puts "\n Try with manager: #{manager.to_json}"
    end
    false
  end

  # def user_level(user)   # A user no longer has a level. Users no have responsibiity levels
  #   begin
  #     # see http://stackoverflow.com/questions/2244915/how-do-i-search-within-an-array-of-hashes-by-hash-values-in-ruby
  #     return LEVELS.select{ |l| l[:user_type] == user.type}.first[:count]
  #   rescue
  #     return 0
  #   end
  # end

  def manage_locations   #tested
    return nil if self.type == 'Player'
    return Location.all if self.type == 'Staff'
    manager_locations = []
    for loc in self.locations
      manager_locations << loc
      locs = loc.descendant_locations
      manager_locations.push(*locs) unless locs == nil
    end
    return manager_locations
  end

  def countries
    responsibilities = Responsibility.where("user_id=?", self)
    return [] if responsibilities.empty?
    locations = []
    responsibilities.each do |resp|
      locations << resp.location if resp.location.is_a?(Country)
    end
    return locations
  end  

  def master_regions
    responsibilities = Responsibility.where("user_id=?", self.id)
    return [] if responsibilities.empty?
    locations = []
    responsibilities.each do |resp|
      locations << resp.location if resp.location.is_a?(MasterRegion)
    end
    return locations
  end

  def regions
    responsibilities = Responsibility.where("user_id=?", self.id)
    return [] if responsibilities.empty?
    locations = []
    responsibilities.each do |resp|
      locations << resp.location if resp.location.is_a?(Region)
    end
    return locations
  end

  def venues
    responsibilities = Responsibility.where("user_id=?", self.id)
    return [] if responsibilities.empty?
    locations = []
    responsibilities.each do |resp|
      locations << resp.location if resp.location.is_a?(Venue)
    end
    return locations
  end

  def roles
    roles = Userrole.where("user_id=?", self.id)
  end

  def adjust_logons(succeeded = true)
    return true unless self.active
    if succeeded 
      self.failed_logons = 0 if self.failed_logons > 0
    else
      self.failed_logons += 1
      self.active = false if self.failed_logons > 5
    end
  end

end
