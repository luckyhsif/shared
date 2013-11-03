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

  def self.available_permissions_for(user)
    #returns the permissions that may be added to user
    return user.permissions
  end

  def self.immediate_manager_of(user)
    return nil if user == nil || user.type == 'Staff'
    case user.class
      when Player
      else
    end
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
  
  def included_locations
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
    responsibilities = Responsibility.where("user_id = ?", self)
    return nil unless responsibilities
    roles = []
    responsibilities.each do |r|
      roles << r.role
    end
    highest_role = roles.max { |a,b| a.level <=> b.level}
  end

  def immediate_subordinates
    responsibilities = Responsibility.where("manager = ?", params[self])
    s = []
    responsibilities.each do |r|
      s << r.user
    end
  end

  def immediate_subordinates_old
    # The immediate subordinates of a Staff Member are always Country Distributors
    # The immediate subordinates of a Country Distributor may be master distributors
    #   but not necessarily, or
    # The immediate subordinates of a Country Distributor may be regional distributors,
    #   but not necessarily
    # If neither master distributors nor regional distributors exist, the immediate 
    #   subordinates of a counter distributors will be agents 

    return self.location.players if user_level(self) == 2
    return CountryDistributor.all if user_level(self) == 7
    users = []
    case self.type
      when 'Agent'
        for location in self.locations
          for emp in location.employees
            users << emp
          end
        end
      when 'RegionalDistributor'
        for location in self.locations
          for loc in location.children   # loc is an agent location
            users << loc.agent if loc.agent
          end
        end
      when 'MasterDistributor'
        for location in self.locations 
          for loc in location.children   # loc can be a Region Loc or an Agent Loc
            if loc.regional_distributor  # It is a RD location, so provide a list of RD's
              users << loc.regional_distributor
            elsif loc.agent              
              users << loc.agent
            end
          end
        end
      when 'CountryDistributor'
        for location in self.locations   # location is a Country location
          for loc in location.children   # loc can be a Master Loc, a Region Loc or an Agent Loc
            if loc.master_distributor    
              users << loc.master_distributor
            elsif loc.regional_distributor 
              users << loc.regional_distributor
            elsif loc.agent
              users << loc.agent
            end
          end
        end
    end
    return users
  end

  def all_subordinates
    # This method is not completed because this will probably not be necessary
    return self.location.players if [2,3].include? user_level(self)
    return User.all if user_level(self) == 7
    users = []
    for location in self.locations
      for master_loc in location.children
        case self.type
          when 'CountryDistributor'
            mds = []
            rds = []
            ags = []
            mds << master_loc.master_distributor if master_loc.master_distributor
            users.push(*mds)
            for region_loc in master_loc.children
              rds << region_loc.regional_distributor if region_loc.regional_distributor
              users.push(*rds)
              for agent_loc in region_loc.children
                ags << agent_loc.agent if agent_loc.agent
              end
            end
          when 'MasterDistributor'
            users << child_loc.regional_distributor if child_loc.regional_distributor
          when 'RegionalDistributor'
            users << child_loc.agent
        end
      end
    end
    return users
  end

  def user_level(user)
    begin
      # see http://stackoverflow.com/questions/2244915/how-do-i-search-within-an-array-of-hashes-by-hash-values-in-ruby
      return LEVELS.select{ |l| l[:user_type] == user.type}.first[:count]
    rescue
      return 0
    end
  end

  # def allowed_to_enquire_for(user)
  #   return false if user == nil
  #   manager_level = user_level(self)
  #   subordinate_level = user_level(user)
  #   return manager_level > subordinate_level
  # end

  def own_locations
    case self.type
      when 'Staff'
        Location.country_locations
      when 'CountryDistributor', 'MasterDistributor', 'RegionalDistributor', 'Agent'
        self.locations
      when 'Employee'
        self.location
      else
        nil
    end
  end

  def manage_locations
    return [self.location] if user_level(self) < 3   # player.location or employee.location
    manager_locations = []
    for loc in self.locations   # if self eq agent then loc is agent loc
      manager_locations << loc
      if user_level(self) > 3
        locs = loc.descendant_locations
        manager_locations.push(*locs) unless locs == nil
      end
    end
    return manager_locations
  end

  def manage_players
    return nil if user_level(self) == 1                    # Can't be a player
    return self.location.players if user_level(self) == 2  # Players belonging to employee's location
    return Players.all if user_level(self) == 7            # Staff member manages everybody
    locations = self.manage_locations
    players = []
    for location in locations
      players.push(*location.players)
    end
    return players
  end

  def includes_location?(user)
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
