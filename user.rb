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

  def allowed_to_enquire_for(wanted_user)
    return false if wanted_user == nil
    manager_level = user_level(self)
    subordinate_type = user_level(wanted_user)
    return manager_level > subordinate_type
  end

  def includes_location?(user)
    return false if user == nil
    manager_level = user_level(self)
    subordinate_level = user_level(user)
    return false unless manager_level > subordinate_level
    return self.location == user.location if manager_level < 4
    manager_locations = []
    for loc in self.locations 
      manager_locations << loc.descendant_locations
    end
    manager_locations = manager_locations.flatten
    # puts "All manager locations"
    # for loc in manager_locations
    #   puts loc.name
    # end
    return manager_locations.include? user.location if subordinate_level < 4
    return manager_locations.include? user.locations.first
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
