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
  
  def account(name, currency = Currency.default)
    return self.accounts.where(name: name.to_s, currency: currency).first_or_create
  end

  def players(offset=0, limit=0)
    player_ids = "SELECT U.id FROM users U" \
      " LEFT OUTER JOIN locations L ON U.venue_id = L.id" \
      " WHERE L.id = #{self.id}" \
      " AND U.type = 'Player'"
    total = (Player.find_by_sql [player_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT P.* FROM users P"  \
      " LEFT OUTER JOIN locations L ON P.venue_id = L.id" \
      " WHERE L.id = #{self.id}" \
      " AND P.type = 'Player'" \
      " ORDER BY P.name LIMIT #{limit} OFFSET #{calculated_offset}"
    players = Player.find_by_sql [sqlstr]
    results = [players, total]
  end

  def agent
    role = Role.find_by_name('Agent')
    #rlist = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    rlist = Responsibility.where("role_id=? AND location_id=?", role.id, self)
    return nil if rlist.empty?
    User.find_by_id(rlist.first.user.id)
  end

  def has_employee?(employee) 
    role = Role.find_by_name('Employee')
    rlist = Responsibility.find_by_sql ["SELECT user_id FROM responsibilities r WHERE r.role_id = ? AND r.location_id = ?", role.id, self.id]
    return rlist.count > 0
  end

  def managers_for_sublocations
    managers = Hash.new
    return managers
  end

  def self.title_for_lists
    return 't.location.venue.plural'
  end

  def self.title_for_location_names
    return 't.location.venue.location_heading'
  end

  def self.title_for_managers
    return 't.location.venue.manager_heading'
  end

  def self.buttons_for_children_list
    return 't.location.venue.add'
  end

  def self.button_label
    return 't.location.venue.add'
  end

  private
  
    def may_not_have_children
      #errors.add_to_base("A Venue may not have children") unless self.children.empty?
      errors[:base] << "A Venue may not have children" unless self.children.empty?
    end

end
