class MasterDistributor < User
  has_many :locations, inverse_of: :master_distributor
  validate :has_a_location
  protected
  def has_a_location
    if self.locations.empty?
      errors.add(:location, "MasterDistributor must have at least one Location.")
    end
  end
end
