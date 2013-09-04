class RegionalDistributor < User
  has_many :locations, inverse_of: :regional_distributor
  validate :has_a_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "RegionalDistributor must have at least one Location.")
    end
  end
end
