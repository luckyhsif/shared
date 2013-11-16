class Role < ActiveRecord::Base

  has_many :grantable_permission_types, class_name: 'PermissionType', foreign_key: :grantable_role_type_id
  has_many :receivable_permission_types, class_name: 'PermissionType', foreign_key: :receivable_role_type_id
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

  def subordinate_role_type
    staff_role_type = Role.find_by_name('Staff')
    cd_role_type = Role.find_by_name('Country Distributor')
    md_role_type = Role.find_by_name('Master Distributor')
    rd_role_type = Role.find_by_name('Regional Distributor') 
    agent_role_type = Role.find_by_name('Agent')   
    employee_role_type = Role.find_by_name('Employee')
    player_role_type = Role.find_by_name('Player')
    return cd_role_type if self == staff_role_type
    return md_role_type if self == cd_role_type
    return rd_role_type if self == md_role_type
    return agent_role_type if self == rd_role_type
    return employee_role_type if self == agent_role_type 
    return player_role_type if self == employee_role_type
    return nil
  end
end
