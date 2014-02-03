class Role < ActiveRecord::Base

  has_one :parent, class_name: 'Role', foreign_key: :parent_id
  # has_and_belongs_to_many :grantable_permissions, class_name: 'Permission', 
  #                                                 join_table: 'grantable_permissions_roles', 
  #                                                 association_foreign_key: :permission_id
  # has_and_belongs_to_many :permissions
  validates :name, :presence   => true,
                   :uniqueness => { :case_sensitive => false }
  has_many :locations, through: :responsibilities
  has_many :userroles, foreign_key: :role_id

  def is_senior_to?(role)
    self.level > role.level
  end

  def subordinate_role_type_name
    return 'Country Distributor' if self.name == 'Staff'
    return 'Master Distributor' if self.name == 'Country Distributor'
    return 'Regional Distributor' if self.name == 'Master Distributor'
    return 'Agent' if self.name == 'Regional Distributor'
    return 'Employee' if self.name == 'Agent'
    return 'Player' if self.name == 'Employee'
    return nil
  end

  def next_senior_role_type
    higher_level = self.level + 1
    return nil if higher_level > 7
    role = Role.find_by_sql ["SELECT * FROM roles WHERE roles.level = ?", higher_level]
    return role.first
  end

  def next_junior_role_type
    lower_level = self.level - 1
    return nil if lower_level < 1
    role = Role.find_by_sql ["SELECT * FROM roles WHERE roles.level = ?", lower_level]
    return role.first
  end

end
