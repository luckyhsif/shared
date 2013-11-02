class Responsibility < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :location
  belongs_to :manager, class_name: 'User'

  validates_uniqueness_of :role_id, scope: :location_id, 
       message: "Should only have one role directly responsible for a location"

end