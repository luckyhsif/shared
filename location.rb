class Location < ActiveRecord::Base
  include ActiveModel::Dirty

  validates_uniqueness_of :name
  # validates_presence_of :address
  belongs_to :parent, class_name: 'Location', foreign_key: :parent_id
  has_many :children, class_name: 'Location', foreign_key: :parent_id
  validate :parent_may_not_be_a_circular_reference, :child_may_not_be_self
  has_and_belongs_to_many :users

  def root
    # return the root location, ie the parent at the top (bottom?) of the Location heirarchy
    return self if self.parent == nil
    return self.parent.root
  end
  
  def self.roots
    # return a list of all the Locations with no parents.
    return Location.where("parent_id is NULL")
  end

  def self.country_locations
    return Location.roots
  end

  def self.master_locations(country)
    return country.children
  end

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

  def manager
    self.country_distributor || self.master_distributor || self.regional_distributor || self.agent || nil
  end

  def country_location?
    self.parent == nil
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

  def parent_may_not_be_a_circular_reference
    if (self.parent == self) || (!(self.parent == nil) && (self.parent.parent == self))
      errors.add(:parent, "Can't be self")
    end
  end

  def child_may_not_be_self
    errors.add(:children, "Can't contain self") if children.include?(self)
  end
end
