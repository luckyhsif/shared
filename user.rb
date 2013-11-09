class User < ActiveRecord::Base

  has_and_belongs_to_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :responsibilities
  has_many :locations, through: :responsibilities
  has_many :roles, through: :responsibilities
  has_many :messages, foreign_key: :sender_id
  has_many :managers, class_name: 'User', through: :responsibilities, foreign_key: :manager_id

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
    #returns the permissions for the current user
    return self.permissions
  end

  def manager_for_role(role) 
    responsibilities = Responsibility.find_by_sql ["SELECT manager_id FROM responsibilities r WHERE r.role_id = ? AND r.user_id = ?", role.id, self.id]
    return nil if responsibilities.count == 0
    manager = User.find_by_id(responsibilities.first.manager_id)
    return manager
  end

  def agent_of_employee    #tested
    employee_role = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, employee_role.id)
    return false if rlist.count == 0
    venue_id = rlist.first.location_id
    agent_role = Role.find_by_name('Agent')
    rlist = Responsibility.where("location_id=? AND role_id=?", venue_id, agent_role.id)
    return false if rlist.count == 0
    agent = User.find_by_id(rlist.first.user_id)
    return agent
  end

  def is_employee?   # tested
    employee_role = Role.find_by_name('Employee')
    rlist = Responsibility.where("role_id=? AND user_id=?", employee_role, self)
    return rlist.count > 0
  end

  def is_agent? 
    agent_role = Role.find_by_name('Agent')
    rlist = Responsibility.where("role_id=? AND user_id=?", agent_role, self)
    return rlist.count > 0
  end

  def is_employee_at_venue?(venue)   # tested
    employee_role = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=? AND location_id=?", self.id, employee_role.id, venue.id)
    return rlist.count > 0
  end
  
  def agent_venues    # tested
    venues = []
    role = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, role.id)
    return venues if rlist.count == 0
    rlist.each do |r|
      venue = Venue.find_by_id(r.location_id)
      venues << r.location
    end
    return venues
  end

  def agent_employees    # tested
    employees = []
    agent_role = Role.find_by_name('Agent')
    employee_role = Role.find_by_name('Employee')
    alist = Responsibility.where("user_id=? AND role_id=?", self.id, agent_role.id)
    return employees if alist.count == 0
    alist.each do |a|
      elist = Responsibility.where("role_id=? AND manager_id=?", employee_role.id, a.user_id)
      elist.each do |e|
        employee = User.find_by_id(e.user_id)
        employees << employee
      end
    end
    return employees
  end

  def agent_players     #tested
    agent_role = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self, agent_role)
    players = []
    return players if rlist.count == 0
    rlist.each do |r|
      venue = r.location
      players.push(*venue.players)
    end
    return players
  end

  def employee_players  
    employee_role = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=?", self, employee_role)
    players = []
    return players if rlist.count == 0
    rlist.each do |r|
      venue = r.location
      players.push(*venue.players)
    end
    return players
  end

  def agent_of_player    # tested
    return nil unless self.type == 'Player'
    venue = self.venue
    agent_role = Role.find_by_name('Agent')
    rlist = Responsibility.where("role_id=? AND location_id=?", agent_role.id, venue.id)
    return nil if rlist.count == 0
    agent = User.find_by_id(rlist.first.user_id)
    return agent
  end

  def allowed_to_maintain?(user)   #tested
    subordinate = user
    manager = self
    return false if subordinate == manager
    return false if manager.type == 'Player'
    return true if manager.type == 'Staff'
    manager_role = manager.most_senior_role
    if subordinate.type == 'Player'
      subordinate_role_name = 'Player'
    else
      subordinate_role = subordinate.most_senior_role
      subordinate_role_name = subordinate_role.name
    end
    # puts "Manager: #{manager.name}" 
    # puts "manager role: #{manager_role.name}"
    # puts "Subordinate: #{subordinate.name}" 
    # puts "subordinate role_name: #{subordinate_role_name}"
    return true if manager_role.name == 'Staff'
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
    end
    managers = subordinate.managers
    return managers.include?(manager)
  end

  def managers       #tested
    # Return all the managers for the current user
    managers = []
    if self.type == 'Player'
      subordinate = self
      venue = subordinate.venue
      agent_role = Role.find_by_name('Agent')
      rlist = Responsibility.where("role_id=? AND location_id=?", agent_role.id, venue.id)
      return nil if rlist.count == 0
      agent = User.find_by_id(rlist.first.user_id)
      return nil if agent == nil
      managers << agent
      subordinate = agent
    end
    rlist = Responsibility.find_by_sql ["SELECT manager_id FROM responsibilities r WHERE r.user_id = ?", self.id]
    return managers if rlist.count == 0
    rlist.each do |r|
      if r.manager_id != nil
        manager = User.find_by_id(r.manager_id)
        managers << manager
        managers.push(*manager.managers)
      end
    end
    return managers
  end

  def manager(location)
    # Returns the immediate manager of the current user
    puts "Entering User - manager, self: #{self.to_json}"
    if self.type == 'Player'
      #role = Role.find_by_name('Agent')   # The role is derived from the responsibility
      puts "\n User - manager(loc) - It is a Player"
      responsibilities = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, location.id]
      # The specified location can have only one Agent
      # The agent is the manager of the current player
      manager = User.find_by_id(responsibilities.first.user_id)
      puts "The player's manager is: #{manager.to_json}"
    else  # It is a User
      puts "\n User - manager(loc) - It is a User"
      responsibilities = Responsibility.find_by_sql ["SELECT id, role_id FROM responsibilities r WHERE r.user_id = ? AND r.location_id = ?", self.id, location.id]
      # The current user will have one responsibility for these criteria
      # e.g. user = 'Lisa', role = 'Agent', location = 'Hall 1', manager = 'Greg'
      #      user = 'Lisa', role = 'RD', location = 'Hall 1', manager = 'George'
      responsibility = Responsibility.find_by_id(responsibilities.first.id)
      if !responsibility
        puts "\n User - manager(loc), unexpected error: no manager"
        return nil
      end
      puts "\n User - manager(loc) - Responsibility: #{responsibility.to_json}"
      manager = responsibility.manager
      puts "The user's manager is: #{manager.to_json}"
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
    responsibilities = Responsibility.where("user_id = ?", self)
    return nil unless responsibilities
    locations = []
    responsibilities.each do |r|
      locations << r.location
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

  def most_senior_role      # Tested
    if self.type == 'Player'
      role = create(:role, name: 'Player', level: 1)
      return role
    end  
    if self.type == 'Staff'
      role = create(:staff)
      return role
    end
    responsibilities = Responsibility.where("user_id = ?", self)
    return nil unless responsibilities.count > 0
    return responsibilities.first.role if responsibilities.count == 1
    roles = []
    responsibilities.each do |r|
      roles << r.role
    end
    highest_role = roles.max { |a,b| a.level <=> b.level}
    return highest_role
  end

  def immediate_subordinates    # Tested
    rlist = Responsibility.where("manager_id = ?", self)
    return nil if rlist.count == 0
    users = User.find(rlist.map(&:user_id).uniq)
  end

  def is_subordinate_of?(user, location)    #  still working on this
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

  def user_level(user)   # A user no longer has a level. Users no have responsibiity levels
    begin
      # see http://stackoverflow.com/questions/2244915/how-do-i-search-within-an-array-of-hashes-by-hash-values-in-ruby
      return LEVELS.select{ |l| l[:user_type] == user.type}.first[:count]
    rescue
      return 0
    end
  end

  def manage_locations   #tested
    return nil if self.type == 'Player'
    manager_locations = []
    for loc in self.locations
      manager_locations << loc
      locs = loc.descendant_locations
      manager_locations.push(*locs) unless locs == nil
    end
    return manager_locations
  end

  # def manage_players       
  #   return nil if user_level(self) == 1                    # Can't be a player
  #   return self.location.players if user_level(self) == 2  # Players belonging to employee's location
  #   return Players.all if user_level(self) == 7            # Staff member manages everybody
  #   locations = self.manage_locations
  #   players = []
  #   for location in locations
  #     players.push(*location.players)
  #   end
  #   return players
  # end

  def includes_location?(user)    # Not sure if this is still needed
    # This algorithm determines if the locations belonging to self includes
    #  the locations belonging to user.
    # In the case where the manager (self) and the subornates (user) both have
    #   many locations, the following assumption is made:
    # If one location of the subordinate falls in the location hierarchy of the
    #   manager, then all locations of the subordinate will also pass the test
    return false if user == nil
    manager_level = user_level(self)
    subordinate_level = user_level(user)
    return true if manager_level == 7
    return false if manager_level == 1
    return false unless manager_level > subordinate_level
    # Pick a subordinate test location
    case subordinate_level
      when 3,4,5
        testloc = user.locations.first
      when 1,2
        testloc = user.location
    end
    if [4,5,6].include?(manager_level)
      manager_locations = []
      for loc in self.locations 
        manager_locations << loc
        desc_locs = loc.descendant_locations
        manager_locations.push(*desc_locs) unless desc_locs == nil
      end
    end
    case manager_level
      when 4,5,6
        return manager_locations.include?(testloc)
      when 3
        return self.locations.include?(user.location)
      when 2
        return self.location == user.location
    end
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
