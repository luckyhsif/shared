class Location < ActiveRecord::Base
  include ActiveModel::Dirty

  validates_uniqueness_of :name
  # validates_presence_of :address
  belongs_to :parent, class_name: 'Location', foreign_key: :parent_id
  has_many :children, class_name: 'Location', foreign_key: :parent_id
  validate :parent_may_not_be_a_circular_reference, :child_may_not_be_self
  has_many :players
  has_many :employees
  has_one :agent
  belongs_to :regional_distributor
  belongs_to :master_distributor
  belongs_to :country_distributor

  def root
    # return the root location, ie the parent at the top (bottom?) of the Location heirarchy
    return self if self.parent == nil
    return self.parent.root
  end
  
  def self.roots
    # return a list of all the Locations with no parents.
    return Location.where("parent_id is NULL")
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
