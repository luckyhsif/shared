class Permission < ActiveRecord::Base
  belongs_to :permission_type
  belongs_to :user

#  validates_numericality_of :value, greater_than_or_equal_to: 0

end