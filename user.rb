class User < ActiveRecord::Base
  
  has_and_belongs_to_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :messages, foreign_key: :sender_id
  has_many :accounts, foreign_key: :owner_id, dependent: :destroy
  validates_presence_of :password_hash
  validates_presence_of :name
  validates_presence_of :email
  validates_uniqueness_of :email

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

  def block_player
    self.active = false
  end

  def unblock_player
    self.active = true
  end

  def success_enquiry_for(wanted_user)
    return true   # incomplete
  end

  def password_reset_required?
    return self.password_reset_required
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
