class Permission < ActiveRecord::Base
  has_and_belongs_to_many :users, association_foreign_key: :user_id
  has_and_belongs_to_many :granting_roles, class_name: 'Role', join_table: 'grantable_permissions_roles', association_foreign_key: :role_id
  has_and_belongs_to_many :roles

  validates :name,  :presence   => true, 
                    :length     => { :minimum => 5, :maximum => 50 }, 
                    :uniqueness => { :case_sensitive => false }
end
