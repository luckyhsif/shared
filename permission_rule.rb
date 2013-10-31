class PermissionRule < ActiveRecord::Base
  belongs_to :permission
  belongs_to :grantable_by, class_name: 'Role'
  belongs_to :grantable_upon, class_name: 'Role'


  def senior_must_grant_upon_junior
    
  end
end