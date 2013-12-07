class Location < ActiveRecord::Base
  include ActiveModel::Dirty

  validates :name, :presence   => true,
                   :uniqueness => { :case_sensitive => false }
  belongs_to :parent, class_name: 'Location', foreign_key: :parent_id
  has_many :children, class_name: 'Location', foreign_key: :parent_id
  has_many :responsibilities
  has_many :users, through: :responsibilities
  has_many :roles, through: :responsibilities
  has_and_belongs_to_many :users

  default_scope order('name ASC')

  validate :parent_may_not_be_a_circular_reference, :child_may_not_be_self, 
            :parent_may_not_be_venue
  before_save :may_not_be_a_parent_in_child_hierarchy

  def root
    # return the root location, ie the parent at the top (bottom?) of the Location heirarchy
    return self if self.parent == nil
    return self.parent.root
  end
  
  def self.roots
    # return a list of all the Locations with no parents.
    return Location.where("parent_id is NULL")
  end

  def can_be_removed?
    if self.is_a?(Venue) && !self.players.empty?
        return false
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

  def self.country_locations
    return Location.roots
  end

  def self.master_locations(country)
    return country.children
  end
  
  # def subordinate_manager_names
  #   managers = Hash.new
  #   # If self type eq Country, then find Master Distributors for the child Master Regions
  #   #   providing a lookup  managers[master-region.id] = manager_name
  #   # If self type eq MasterRegion, then find Region Distributors for the chil

  #   cd_role_type = Role.find_by_name('Country Distributor')
  #   Country.all.each do |country|
  #     resps = Responsibility.where("location_id=?", country.id)
  #     managers[country.id] = resps.first.user.name unless resps.empty?
  #   end
  #   return managers
  # end

  def self.regional_locations(country)
    regional_locations = []
    for ml in Location.master_locations(country)
      regional_locations.push(*ml.children)
    end
    return regional_locations
  end

  def self.agent_locations(country)
    agent_locations = []
    for rl in Location.regional_locations
      agent_locations.push(*rl.children)
    end
    return agent_locations
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

  private

  def may_not_be_a_parent_in_child_hierarchy
    # get the immediate children of the last created object
    # for each child, see if that child is a parent as well
    # testloc = Location.last
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
