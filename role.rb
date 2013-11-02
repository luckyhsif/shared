class Role < ActiveRecord::Base
  has_one :parent, class_name: 'Role', foreign_key: :parent_id
  has_and_belongs_to_many :grantable_permissions, class_name: 'Permission', 
                                                  join_table: 'grantable_permissions_roles', 
                                                  association_foreign_key: :permission_id
  has_and_belongs_to_many :permissions
  validates :name, :presence   => true,
                   :uniqueness => { :case_sensitive => false }
  has_many :locations, through: :responsibilities
  has_many :users, through: :responsibilities

  def is_senior_to?(role)
    while role.parent != nil
      
    end
  end
end
