class PermissionType < ActiveRecord::Base
  belongs_to :granting_role_type, class_name: 'Role'
  belongs_to :receiving_role_type, class_name: 'Role' 
  #   , join_table: 'grantable_permissions_roles', association_foreign_key: :role_id

  validates :name,  :presence   => true, 
                    :length     => { :minimum => 5, :maximum => 50 }, 
                    :uniqueness => { :case_sensitive => false }
end
