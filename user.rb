require 'rfc-822'
class User < ActiveRecord::Base

  has_many :permissions, foreign_key: :user_id
  has_many :permission_types, through: :permissions
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :responsibilities
  has_many :locations, through: :responsibilities
  has_many :messages, foreign_key: :sender_id
  has_many :userroles, foreign_key: :user_id
  #has_many :roles, through: :userroles
  has_many :credentials
  has_many :txids, class_name: 'TxId'
  has_many :logs, class_name: 'ISoftbetLog'
  has_many :gameplays
  has_many :games, through: :gameplays
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy
  has_many :deposits
  has_many :withdrawals
  has_many :accepted_bonuses, class_name: 'AcceptedBonus'
  belongs_to :currency
  belongs_to :country

  default_scope { order('name ASC') }

  email_regex = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i

  validates :email, :presence   => true,
                    :format     => { :with => RFC822::EMAIL },
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

  def credential(name)
    return self.credentials.where(name: name.to_s).first_or_create
  end

  def self.search(search)
    users = find_by_sql ["SELECT * FROM users WHERE name LIKE ? ORDER BY users.name ASC", "%#{search}%"]
  end

  def self.search_by_partial_name(search)
    sql = "SELECT * FROM users"
    sql += " WHERE firstname LIKE ? OR name LIKE ? "
    sql += " ORDER BY users.firstname ASC, users.name ASC"
    users = find_by_sql [sql, "%#{search}%", "%#{search}%"]
  end

  def user_roles
    urs = Userrole.where("user_id=?", self.id)
  end

  def self.search(role_id, enquirer, search)
    user_ids = find_by_sql ["SELECT u.id FROM users u WHERE u.name LIKE ?", "%#{search}%"]
    role = Role.find_by_id(role_id)
    idlist = []
    user = nil
    user_ids.each do |uid|
      user = User.find_by_id(uid)
      case role.name
      when 'Player'
        if user 
          managers = user.managers
          idlist << uid if user && user.is_a?(Player) && (enquirer.is_a?(Staff) || managers.include?(enquirer))
        end
      when 'Employee'
        managers = user.managers
        idlist << uid if user && user.is_employee? && (enquirer.is_a?(Staff) || managers.include?(enquirer))
      when 'Agent'
        if user && user.is_agent?
          if enquirer.is_a?(Staff) 
            idlist << uid
          else
            managers = user.managers
            idlist << uid if managers.include?(enquirer)
          end
        end
      when 'Regional Distributor'
        if user && user.is_regional_distributor?
          if enquirer.is_a?(Staff) 
            idlist << uid
          else
            managers = user.managers
            idlist << uid if managers.include?(enquirer)
          end
        end
      when 'Master Distributor'
        if user && user.is_master_distributor?
          if enquirer.is_a?(Staff) 
            idlist << uid
          else
            managers = user.managers
            idlist << uid if managers.include?(enquirer)
          end
        end
      when 'Country Distributor'
        if user && user.is_country_distributor?
          if enquirer.is_a?(Staff) 
            idlist << uid
          else
            managers = user.managers
            idlist << uid if managers.include?(enquirer)
          end
        end
      when 'Staff'
        idlist << uid if user && enquirer.is_a?(Staff)
      end
    end
    users = idlist.map { |id| User.find_by_id(id) }
    users.sort! { |a,b| a.name <=> b.name }
  end

  def full_name
    if self.is_a? Player
      self.firstname + ' ' + self.name
    else
      self.name
    end
  end

  def user_role_types_sorted
    urtypes = self.user_roles.map { |urole| urole.role }
    urtypes.sort! { |a,b| a.level <=> b.level }
  end

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

  def unmanaged_master_regions
    # self is a country distributor
    # First collect all the countries assigned to self,
    # then gather all master regions that are children of these countries.
    # Return all the master regions that are not allocated to a user
    master_regions = []
    resps = Responsibility.where("user_id=?", self)
    return master_regions if resps.empty?
    countries = []
    resps.each do |resp|
      countries << resp.location if resp.location.is_a?(Country)
    end
    return master_regions if countries.empty?
    sublocs = []
    countries.each do |country|
      sublocs.push(*country.children)
    end
    sublocs.each do |subloc|
      resps = Responsibility.where("location_id=?", subloc)
      master_regions << subloc if resps.empty?
    end
    return master_regions if master_regions.count < 2
    master_regions.sort! { |a,b| a.name <=> b.name }
  end

  def unmanaged_regions
    # self is a master distributor
    # First collect all the master regions assigned to self,
    # then gather all regions that are children of these master regions.
    # Return all the regions that are not allocated to a user.
    regions = []
    resps = Responsibility.where("user_id=?", self)
    return regions if resps.empty?
    master_regions = []
    resps.each do |resp|
      master_regions << resp.location if resp.location.is_a?(MasterRegion)
    end
    return regions if master_regions.empty?
    sublocs = []
    master_regions.each do |mregion|
      sublocs.push(*mregion.children)
    end
    sublocs.each do |subloc|
      resps = Responsibility.where("location_id=?", subloc)
      regions << subloc if resps.empty?
    end
    return regions if regions.count < 2
    regions.sort! { |a,b| a.name <=> b.name }
  end

  def unmanaged_venues
    # self is a regional distributor.
    # First collect all the regions assigned to self,
    # then gather all venues that are children of these regions.
    # Return all the children that are not allocated to a user.
    venues = []
    resps = Responsibility.where("user_id=?", self)
    return venues if resps.empty?
    regions = []
    resps.each do |resp|
      regions << resp.location if resp.location.is_a?(Region)
    end
    return venues if regions.empty?
    sublocs = []
    regions.each do |reg|
      sublocs.push(*reg.children)
    end
    sublocs.each do |subloc|
      resps = Responsibility.where("location_id=?", subloc)
      venues << subloc if resps.empty?
    end
    return venues if venues.count < 2
    venues.sort! { |a,b| a.name <=> b.name }
  end

  def self.unmanaged_countries
    countries = []
    Country.all.each do |country| 
      resps = Responsibility.where("location_id=?", country)
      countries << resps.first.location unless resps.empty?
    end 
    return countries if countries.count < 2
    countries.sort! { |a,b| a.name <=> b.name }
  end

  def available_permissions
    return self.permissions
  end

  def unused_permission_types
    senior_role = self.most_senior_role
    userrole = Userrole.find(self, senior_role) 
    return nil if userrole.nil?
    available_permission_types = []
    if senior_role.name == 'Country Distributor' 
      available_permission_types = PermissionType.all.to_a
    else
      return nil if userrole.manager.permissions.nil?
      available_permission_types = userrole.manager.permissions.to_a.map { |perm| perm.permission_type }
    end
    unused = available_permission_types - self.permissions.to_a.map {|perm| perm.permission_type }
  end

  def unused_permissions
    # Since this method returns the permissions of the user's manager, 
    #  it cannot be used for country distributors
    senior_role = self.most_senior_role
    return nil if senior_role.name == 'Country Distributor'
    userrole = Userrole.find(self, senior_role) 
    return nil if userrole.nil? || userrole.manager.permissions.nil? 
    used_perm_types = self.permissions.to_a.map {|perm| perm.permission_type }
    manager_perm_types = userrole.manager.permissions.to_a.map { |perm| perm.permission_type }
    unused_perms = []
    userrole.manager.permissions.each.map { |ump| unused_perms << ump unless used_perm_types.include?(ump.permission_type) }
    return unused_perms
  end

  def agent_of_employee
    employee_role_type = Role.find_by_name('Employee')
    rlist = Userrole.where("user_id=? AND role_id=?", self.id, employee_role_type.id)
    return nil if rlist.empty?
    agent = rlist.first.manager
  end

  def is_employee?
    employee_role_type = Role.find_by_name('Employee')
    uroles = Userrole.where("role_id=? AND user_id=?", employee_role_type.id, self.id)
    return true if uroles.count > 0
    rlist = Responsibility.where("role_id=? AND user_id=?", employee_role_type.id, self.id)
    return rlist.count > 0
  end

  def is_agent? 
    agent_role_type = Role.find_by_name('Agent')
    uroles = Userrole.where("role_id=? AND user_id=?", agent_role_type.id, self.id)
    return true if uroles.count > 0
    rlist = Responsibility.where("role_id=? AND user_id=?", agent_role_type.id, self.id)
    return rlist.count > 0
  end

  def is_regional_distributor?
    rd_role_type = Role.find_by_name('Regional Distributor')
    uroles = Userrole.where("role_id=? AND user_id=?", rd_role_type.id, self.id)
    return uroles.count > 0
  end

  def is_master_distributor?
    md_role_type = Role.find_by_name('Master Distributor')
    uroles = Userrole.where("role_id=? AND user_id=?", md_role_type.id, self.id)
    return uroles.count > 0
  end

  def is_country_distributor?
    cd_role_type = Role.find_by_name('Country Distributor')
    uroles = Userrole.where("role_id=? AND user_id=?", cd_role_type.id, self.id)
    return uroles.count > 0
  end

  def is_employee_at_venue?(venue)
    employee_role_type = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=? AND location_id=?", self.id, employee_role_type.id, venue.id)
    return rlist.count > 0
  end
  
  def agent_venues
    agent_role_type = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, agent_role_type.id)
    #venues = Venue.find(rlist.map(&:location_id).uniq) unless rlist.empty?
    return venues if rlist.empty?
    venues = rlist.map { |resp| resp.location }
    return venues if venues.count < 2
    venues.sort! { |a,b| a.name <=> b.name }
  end

  def employee_venues
    venues = []
    return venues unless self.is_employee?
    role = Role.find_by_name('Employee')
    rlist = Responsibility.where("user_id=? AND role_id=?", self.id, role.id)
    venues = Venue.find(rlist.map(&:location_id).uniq)
    return venues if venues.count < 2
    venues.sort! { |a,b| a.name <=> b.name }
  end

  def agent_employees(offset=0, limit=0)
    employee_role_type = Role.find_by_name('Employee')
    #employee_roles = Userrole.where("role_id=? AND manager_id=?", employee_role_type.id, self.id)
    employee_role_ids = "SELECT Employee.id FROM userroles UR" \
      " LEFT OUTER JOIN users Employee ON UR.user_id = Employee.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND UR.manager_id = #{self.id}"
    total = (User.find_by_sql [employee_role_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT Employee.* FROM users Employee"  \
      " LEFT OUTER JOIN userroles UR ON UR.user_id = Employee.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND UR.manager_id = #{self.id}" \
      " ORDER BY Employee.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    employees = User.find_by_sql [sqlstr]
    results = [employees, total]
  end

  def agent_players(offset=0, limit=0)
    player_count = 0
    agent_role_type = Role.find_by_name('Agent')
    player_ids = "SELECT Player.id FROM responsibilities RE"  \
      " LEFT OUTER JOIN roles ON RE.role_id = roles.id" \
      " LEFT OUTER JOIN users Agent ON RE.user_id = Agent.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " LEFT OUTER JOIN users Player ON Player.venue_id = L.id" \
      " WHERE roles.id = #{agent_role_type.id}" \
      " AND Agent.id = #{self.id}" \
      " AND Player.type = 'Player'"
    total = (User.find_by_sql [player_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT Player.* FROM responsibilities RE"  \
      " LEFT OUTER JOIN roles ON RE.role_id = roles.id" \
      " LEFT OUTER JOIN users Agent ON RE.user_id = Agent.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " LEFT OUTER JOIN users Player ON Player.venue_id = L.id" \
      " WHERE roles.id = #{agent_role_type.id}" \
      " AND Agent.id = #{self.id}" \
      " AND Player.type = 'Player'" \
      " ORDER BY Player.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    players = User.find_by_sql [sqlstr]
    results = [players, total]
  end

  def employee_players(offset=0, limit=0)
    player_count = 0
    employee_role_type = Role.find_by_name('Employee')
    player_ids = "SELECT Player.id FROM responsibilities RE"  \
      " LEFT OUTER JOIN roles ON RE.role_id = roles.id" \
      " LEFT OUTER JOIN users Employee ON RE.user_id = Employee.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " LEFT OUTER JOIN users Player ON Player.venue_id = L.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND Employee.id = #{self.id}"
    total = (User.find_by_sql [player_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT Player.* FROM responsibilities RE"  \
      " LEFT OUTER JOIN roles ON RE.role_id = roles.id" \
      " LEFT OUTER JOIN users Employee ON RE.user_id = Employee.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " LEFT OUTER JOIN users Player ON Player.venue_id = L.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND Employee.id = #{self.id}" \
      " ORDER BY Player.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    players = User.find_by_sql [sqlstr]
    results = [players, total]
  end

  def agent_players2  # Delete when no longer needed
    agent_role_type = Role.find_by_name('Agent')
    rlist = Responsibility.where("user_id=? AND role_id=?", self, agent_role_type)
    players = []
    return players if rlist.empty?
    rlist.each do |r|
      venue = r.location
      venue_players = Player.where("venue_id=?", venue.id)
      players.push(*venue_players)
    end
    return players
  end

  def manages_user?(user)
    subordinate = user
    manager = self
    return false if subordinate == manager
    return false if manager.active == false
    return false if manager.is_a?(Player)
    return true if manager.is_a?(Staff)
    manager_role = manager.most_senior_role
    if subordinate.is_a?(Player)
      subordinate_role_name = 'Player'
    else
      subordinate_role = subordinate.most_senior_role
      return false if subordinate_role.nil? 
      subordinate_role_name = subordinate_role.name
    end
    if manager_role.name == 'Employee' 
      return false unless subordinate.is_a?(Player)
      return subordinate.venue.has_employee?(manager)
    end
    if manager_role.name == 'Agent'
      if subordinate_role_name == 'Player'
        venues = manager.agent_venues
        return manager.agent_venues.include?(subordinate.venue) 
      elsif subordinate_role_name == 'Employee'
        venues, total = manager.agent_employees(0,1000)
        return venues.include?(subordinate)
      else
        return false
      end
    end
    if subordinate_role_name == 'Player'
      subordinate = subordinate.agent
    elsif subordinate_role_name == 'Employee'
      subordinate = subordinate.agent_of_employee
      return false if subordinate.nil? 
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
    locids = responsibilities.map { |r| r.location.id }
    # If a location has directly been assigned to self, it may only be viewed
    return 'VIEW' if locids.include?(child_location.id)
    child_loc_parent_ids = child_location.parent_location_ids
    locids.each do |locid|
      return 'ALL' if child_loc_parent_ids.include?(locid)
    end
    'NONE'
  end

  # Find the manager of the user's most senior role
  def manager
    return self.agent if self.is_a?(Player)
    return nil if self.is_a?(Staff)
    own_most_senior_role_type = self.most_senior_role
    return nil if own_most_senior_role_type.nil?
    user_role = Userrole.where("user_id=? AND role_id=?", self.id, own_most_senior_role_type.id)
    return nil if user_role.nil?
    user_role.first.manager
  end

  def managers 
    managers = []
    if self.type == 'Player'
      managers << self.agent
    end

    if managers.empty?
      uroles = Userrole.where("user_id=?", self.id)
    else
      uroles = Userrole.where("user_id=?", managers.first.id)
    end
    return managers if uroles.empty?
    
    while !uroles.first.manager.nil? do
      next_manager = uroles.first.manager
      managers << next_manager
      uroles = Userrole.where("user_id=?", next_manager.id)
    end
    return managers
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
    p = PermissionType.find_by_name(perm_name)
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

  def allocated_locations_most_senior_role
    return [] if self.type == 'Staff'
    locations = []
    if self.type == 'Player'
      locations << self.venue
      return locations
    end
    role = self.most_senior_role
    responsibilities = Responsibility.where("user_id=? AND role_id=?", self, role)
    locations = responsibilities.map { |resp| resp.location }
    locations.sort! { |a,b| a.name <=> b.name }
  end
  
  def allocated_locations_all_roles
    return [] if self.type == 'Staff'
    return [self.venue] if self.is_a?(Player)
    responsibilities = Responsibility.where("user_id=?", self)
    locs = responsibilities.map { |resp| resp.location if resp.location }
    locs.sort! { |a,b| a.name <=> b.name }
  end

  def location_names_all_roles
    locs = self.allocated_locations_all_roles
    locations_names = locs.map { |loc| loc.name }
    locations_names.sort! { |a,b| a <=> b }
    return locations_names.join(", ")
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
    return locations if locations.count < 2
    dlocs = locations.sort! { |a,b| a.name <=> b.name }
  end
  
  def most_senior_role  
    if self.is_a?(Staff)
      role = Role.find_by_name('Staff')
      puts "Error - staff role not found" if role.nil?
      return role
    end
    if self.is_country_distributor?
      role = Role.find_by_name('Country Distributor')
      puts "Error - country distributor role not found" if role.nil?
      return role
    end
    if self.is_master_distributor?
      role = Role.find_by_name('Master Distributor')
      puts "Error - master distributor role not found" if role.nil?
      return role
    end
    if self.is_regional_distributor?
      role = Role.find_by_name('Regional Distributor')
      puts "Error - regional distributor role not found" if role.nil?
      return role
    end
    if self.is_agent?
      role = Role.find_by_name('Agent')
      puts "Error - agent role not found" if role.nil?
      return role
    end
    if self.is_employee?
      role = Role.find_by_name('Employee')
      puts "Error - employee role not found" if role.nil?
      return role
    end
    if self.is_a?(Player)
      role = Role.find_by_name('Player')
      puts "Error - player role not found" if role.nil?
      return role
    end
    nil
  end

  def immediate_subordinates
    urlist = Userrole.where("manager_id = ?", self)
    return nil unless urlist && urlist.count > 0
    users = User.find(urlist.map(&:user_id).uniq)
    return users if users.count < 2
    users.sort! { |a,b| a.name <=> b.name }
  end

  # def user_level(user)   # A user no longer has a level. Users no have responsibiity levels
  #   begin
  #     # see http://stackoverflow.com/questions/2244915/how-do-i-search-within-an-array-of-hashes-by-hash-values-in-ruby
  #     return LEVELS.select{ |l| l[:user_type] == user.type}.first[:count]
  #   rescue
  #     return 0
  #   end
  # end

  def included_locations
    # Returns all locations that the user is directly responsible for,
    # including their child locations. A user is therefore allowed to 
    # maintain any locations in this list.
    return [] if self.type == 'Player'
    return Location.all if self.type == 'Staff'
    immediate_locations = self.allocated_locations_most_senior_role
    all_locations = []
    all_locations.push(*immediate_locations)
    immediate_locations.each do |l|
      dl = l.descendant_locations
      all_locations.push(*dl)
    end
    return all_locations
  end

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
