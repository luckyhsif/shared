class MasterDistributor < User
  has_many :locations, inverse_of: :master_distributor
  validate :has_a_location, :may_not_have_same_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "MasterDistributor must have at least one Location.")
    end
  end

  def may_not_have_same_location
  	md_id = self.locations.last 
  	  if md_id.master_distributor_id != self.id 
  	  	errors.add(:location, "Shares the same location as another MasterDistributor")
  	  end
  end
end
