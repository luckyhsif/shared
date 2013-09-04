require_relative 'user'

class RegionalDistributor < User
  has_many :locations, inverse_of: :regional_distributor
  validate :has_a_location, :may_not_have_same_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "RegionalDistributor must have at least one Location.")
    end
  end

  def may_not_have_same_location
    rd_id = self.locations.last 
  	  if rd_id.regional_distributor_id != self.id 
  	  	errors.add(:location, "Shares the same location as another RegionalDistributor")
  	  end
  end

end
