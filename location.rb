class Location < ActiveRecord::Base
  include ActiveModel::Dirty

  validates :name, :presence   => true,
                   :uniqueness => { :scope => :parent_id,  
                                    :case_sensitive => false },
                   :length => { :in => 2..50}
  belongs_to :parent, class_name: 'Location', foreign_key: :parent_id
  has_many :children, class_name: 'Location', foreign_key: :parent_id
  has_many :responsibilities
  has_many :users, through: :responsibilities
  has_many :roles, through: :responsibilities
  has_many :dial_prefixes
  #has_and_belongs_to_many :users

  default_scope { order('name ASC') }

  validate :parent_may_not_be_a_circular_reference, :child_may_not_be_self, 
            :parent_may_not_be_venue
  before_create :may_not_be_a_parent_in_child_hierarchy

class Screen < ActiveRecord::Base
  belongs_to :user
  validates :screen_size, :numericality => {:less_than_or_equal_to =>100, :greater_than_or_equal_to => 0}, :if => lambda {|s| s.user.access == 1 }
end

  def root
    # return the root location, ie the parent at the top (bottom?) of the Location heirarchy
    return self if self.parent == nil
    return self.parent.root
  end
  
  def self.roots
    # return a list of all the Locations with no parents.
    return Location.where("parent_id is NULL")
  end

  def self.exists_within_parent?(child_loc_name, parent_loc)
    testloc = self.find_by_name(child_loc_name)
    return false if testloc.nil?
    testloc.parent === parent_loc ? true : false
  end

  def can_be_removed?
    if self.is_a?(Venue) 
      players, total = self.players
      return total == 0 ? true : false
    end
    rs = Responsibility.where("location_id=?", self)
    return rs.empty?
  end

  def subordinate_type
    return 'MasterRegion' if self.is_a?(Country)
    return 'Region' if self.is_a?(MasterRegion)
    return 'Venue' if self.is_a?(Region)
    nil
  end    

  def self.unallocated_root_locations
    root_locations = []
    Location.roots.each do |root|
      rs = Responsibility.where("location_id=?", root.id)
      root_locations << root if rs.empty?
    end
    return root_locations
  end

  def self.master_locations(country)
    return country.children
  end
  
  def immediate_children(offset=0, limit=0)
    loc_ids = "SELECT Child.id FROM locations Child" \
      " WHERE Child.parent_id = #{self.id}"
    total = (Location.find_by_sql [loc_ids]).count
    parent_loc = Location.find_by_id(self.id)
    calculated_offset = offset * limit
    sqlstr = "SELECT Child.* FROM locations Child" \
      " WHERE Child.parent_id = #{self.id}"
      " ORDER BY Child.name LIMIT #{limit} OFFSET #{calculated_offset}"
    locations = Location.find_by_sql [sqlstr]
    results = [locations, total]
  end

  def parent_location_ids
    return nil unless self.parent
    loc_parents = []
    parent = self.parent
    while parent != nil
      loc_parents << parent.id
      parent = parent.parent
    end
    return loc_parents
  end

  def manager
    responsibilities = Responsibility.where("location_id=?", self.id)
    return nil if responsibilities.empty?
    return responsibilities.first.user
  end

  def country_location?
    self.parent == nil
  end

  def country
    case self.type
    when 'Country'
      nil
    when 'MasterRegion'
      self.parent
    when 'Region'
      self.parent.parent
    when 'Venue'
      self.parent.parent.parent
    end      
  end

  def descendant_venues
    return nil if self.children == nil
    all_children = []
    for child in self.children
      all_children << child if child.is_a?(Venue)
      child_locs = child.descendant_locations
      all_children.push(*child_locs) unless child_locs == nil
    end
    return all_children
  end 

  def descendant_locations
    return nil if self.children == nil
    all_children = []
    for child in self.children
      all_children << child
      child_locs = child.descendant_locations
      all_children.push(*child_locs) unless child_locs == nil
    end
    return all_children
  end

  def valid_parent?(parent_to_be)
    tree = self.leaves
    return tree.include(parent_to_be)
  end

  def all_parents
    parents = []
    current = self
    while current.parent do
      parents << current.parent
      current = current.parent
    end
    return parents
  end

  def is_appropriate_location_for?(user)
    case self.type
    when 'Venue'
      return false unless (user.is_employee? || user.is_agent?)
    when 'Region'
      return false unless user.is_regional_distributor?
    when 'MasterRegion'
      return false unless user.is_master_distributor?
    when 'Country'
      return false unless user.is_country_distributor?
    end
    return true
  end

  private

    def may_not_be_a_parent_in_child_hierarchy
      # get the immediate children of the last created object
      # for each child, see if that child is a parent as well
      #testloc = Location.last
      # testloc = Location.last
      # puts "testloc: #{testloc.to_json}"
      # children = testloc.children if testloc.children
      # return if children.nil? || testloc.parent.nil?
      # parents = testloc.all_parents
      # children.each do |child|
      #   if parents.include?(child)
      #     puts "\n may_not_be_a_parent_in_child_hierarchy"
      #     errors.add(:parent, "Child location may not be a parent at the same time")
      #   end
      # end
    end

    def parent_may_not_be_a_circular_reference
      if (self.parent == self) || (!(self.parent == nil) && (self.parent.parent == self))
        errors.add(:parent, "Can't be self")
      end
    end

    def child_may_not_be_self
      errors.add(:children, "Can't contain self") if children.include?(self)
    end
    
    def parent_may_not_be_venue
      errors.add(:parent, "Can't be a Venue") if !parent.nil? && parent.is_a?(Venue)
    end
end
