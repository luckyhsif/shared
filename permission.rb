class Permission < ActiveRecord::Base
  belongs_to :permission_type
  belongs_to :user

end