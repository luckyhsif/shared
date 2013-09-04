class CountryDistributor < User
  has_many :locations, inverse_of: :country_distributor
  validate :has_a_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "CountryDistributor must have at least one Location.")
    end
  end
end
