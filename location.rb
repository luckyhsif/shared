class Location < ActiveRecord::Base
  validates_uniqueness_of :name
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

  def parent_may_not_be_a_circular_reference
    if parent == self
      errors.add(:parent, "Can't be self")
    end
  end

  def child_may_not_be_self
    errors.add(:children, "Can't contain self") if children.include?(self)
  end
end
