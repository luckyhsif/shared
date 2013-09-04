class CountryDistributor < User
  has_many :locations, inverse_of: :country_distributor
  validate :has_a_location, :may_not_have_same_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "CountryDistributor must have at least one Location.")
    end
  end

  def may_not_have_same_location
    cd_id = self.locations.last 
  	  if cd_id.country_distributor_id != self.id 
  	  	errors.add(:location, "Shares the same location as another CountryDistributor")
  	  end
  end

end
