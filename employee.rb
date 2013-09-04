class Employee < User
  belongs_to :location
  belongs_to :employer, class_name: 'Agent'
  
  validates_presence_of :location
  before_validation :assign_employer
  
  protected
  
  def assign_employer
    if self.location.agent.nil?
      errors.add(:location, "An Employee's Location must have an Agent.")
    else
      self.employer = self.location.agent if self.employer.nil?
    end
  end
end
