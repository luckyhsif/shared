class User < ActiveRecord::Base

  has_and_belongs_to_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :messages, foreign_key: :sender_id
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy

  email_regex = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i

  validates :email, :presence   => true,
                    :format     => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
  validates :name,  :presence   => true, 
                    :length     => { :maximum => 50 }
  validates_presence_of :password_hash

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

  def account(name, currency = Account::DEFAULT_CURRENCY)
    return self.accounts.where(name: name.to_s, currency: currency.to_s).first_or_create
  end

  def balance(name, currency = Account::DEFAULT_CURRENCY)
    return account(name, currency).balance
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

  def immediate_subordinates
    # The immediate subordinates of a Staff Member are always Country Distributors
    # The immediate subordinates of a Country Distributor may be master distributors
    #   but not necessarily, or
    # The immediate subordinates of a Country Distributor may be regional distributors,
    #   but not necessarily
    # If neither master distributors nor regional distributors exist, the immediate 
    #   subordinates of a counter distributors will be agents 
    return self.location.employees if user_level(self) == 3
    return self.location.players if user_level(self) == 2
    return CountryDistributor.all if user_level(self) == 7
    users = []
    for location in self.locations            # for each md location
      #puts "md location = #{location.name}"
      for child_loc in location.children      # for each md child
        #puts "md child location = #{child_loc.name}"      # Agent loc 1
        #puts "agent of md child location = #{child_loc.agent.name}"
        case self.type
          when 'CountryDistributor'
            if child_loc.master_distributor
              users << child_loc.master_distributor 
            elsif child_loc.regional_distributor
              users << child_loc.regional_distributor
            elsif child_loc.agent
              users << child_loc.agent
            end
          when 'MasterDistributor'
            #puts child_loc.to_json
            if child_loc.regional_distributor
              #puts "child_loc.regional_distributor = #{child_loc.regional_distributor.name}"
              users << child_loc.regional_distributor 
            elsif child_loc.agent
              #puts "child_loc.agent = #{child_loc.agent.name}"
              users << child_loc.agent
            end              
          when 'RegionalDistributor'
            users << child_loc.agent if child_loc.agent
          # when 'Agent'
          #   for emp in child_loc.employees
          #     users << emp
          #   end
          # when 'Employee'
          #   for player in child_loc.players
          #     users << player
          #   end
        end
      end
    end
    return users
  end

  def subordinate_type
    case self.type
      when 'Staff' then 'CountryDistributor'
      when 'CountryDistributor' then 'MasterDistributor'
      when 'MasterDistributor' then 'RegionalDistributor'
      when 'RegionalDistributor' then 'Agent'
      when 'Agent' then 'Employee'
      when 'Employee' then 'Player'
      else nil
    end  
  end

  def user_level_name
    case self.type
      when 'Player' then 'Player'
      when 'Employee' then 'Employee'
      when 'Agent' then 'Agent'
      when 'RegionalDistributor' then 'Regional Distributor'
      when 'MasterDistributor' then 'Master Distributor'
      when 'CountryDistributor' then 'Country Distributor'
      when 'Staff' then 'Staff Member'
      else
        99
    end
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
    case user.type
      when 'Player' then 1
      when 'Employee' then 2
      when 'Agent' then 3
      when 'RegionalDistributor' then 4
      when 'MasterDistributor' then 5
      when 'CountryDistributor' then 6
      when 'Staff' then 7
      else
        99
    end
  end

  def allowed_to_enquire_for(user)
    return false if user == nil
    manager_level = user_level(self)
    subordinate_level = user_level(user)
    return manager_level > subordinate_level
  end

  def manage_locations
    return [self.location] if user_level(self) < 4
    #return nil unless user_level(self) > 3
    manager_locations = []
    for loc in self.locations 
      manager_locations << loc
      locs = loc.descendant_locations
      manager_locations.push(*locs) unless locs == nil
    end
    return manager_locations
  end

  def manage_players
    return self.location.players if user_level(self) < 4
    return Players.all if user_level(self) == 7
    locations = self.manage_locations
    puts "manage_players, loc count: #{locations.count}"
    players = []
    for location in locations
      players << location.players
    end
    return players
  end

  def includes_location?(user)
    return false if user == nil
    return true if user_level(self) == 7
    manager_level = user_level(self)
    subordinate_level = user_level(user)
    return false unless manager_level > subordinate_level
    return self.location == user.location if manager_level < 4
    manager_locations = []
    for loc in self.locations 
      manager_locations << loc
      desc_locs = loc.descendant_locations
      manager_locations.push(*desc_locs) unless desc_locs == nil
    end
    return manager_locations.include?(user.location) if subordinate_level < 4
    return manager_locations.include?(user.locations.first)
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
