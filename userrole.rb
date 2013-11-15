class Userrole < ActiveRecord::Base
  #self.table_name = 'userroles'
  belongs_to :user
  belongs_to :role
  belongs_to :manager, class_name: 'User'

  validate :employee_cannot_be_manager

  def subordinate_roles
    # e.g. self eq 'User A' + 'Country Distributor' + 
    # Find user roles where UserA is the manager
    #  'User B' + 'Master Distributor'
    #  'User C' + 'Master Distributor'
    #  'User D' + 'Regional Distributor'
    # Find the most senior role in the list 
    return nil
    manager_role = self.role
    manager = self.user
    subordinate_role_type = nil
  end

  def master_distributor_subordinates
    # Find subordinates who are master distributors
    senior_user = self.user
    empty_list = []
    md_role_type = Role.find_by_name('Master Distributor')
    return empty_list if md_role_type.nil?
    subordinates = Userrole.where("role_id=? AND manager_id=?", md_role_type.id, senior_user.id)
    return subordinates
  end

  def regional_distributor_subordinates
    senior_user = self.user
    empty_list = []
    rd_role_type = Role.find_by_name('Regional Distributor')
    return empty_list if rd_role_type.nil?
    subordinates = Userrole.where("role_id=? AND manager_id=?", rd_role_type.id, senior_user.id)
  end

  def agent_subordinates
    senior_user = self.user
    empty_list = []
    agent_role_type = Role.find_by_name('Agent')
    return empty_list if agent_role_type.nil?
    subordinates = Userrole.where("role_id=? AND manager_id=?", agent_role_type.id, senior_user.id)
  end

  def employee_subordinates
    senior_user = self.user
    empty_list = []
    employee_role_type = Role.find_by_name('Employee')
    return empty_list if employee_role_type.nil?
    subordinates = Userrole.where("role_id=? AND manager_id=?", employee_role_type.id, senior_user.id)
  end

  def most_senior_subordinates
    senior_role_type = self.role
    senior_user = self.user
    senior_user_role = self
    empty_list = []
    case senior_role_type.name
      when 'Country Distributor'
        # Are there any subordinate Master Distributor roles?
        subordinates = senior_user_role.master_distributor_subordinates
        return subordinates if !subordinates.empty?
        # Are there any subordinate Regional Distributor roles?
        subordinates = senior_user_role.regional_distributor_subordinates
        return subordinates if !subordinates.empty?
        # Are there any subordinate Agent roles?
        subordinates = senior_user_role.agent_subordinates
        return subordinates
      when 'Master Distributor'
        # Are there any subordinate Regional Distributor roles?
        subordinates = senior_user_role.regional_distributor_subordinates
        return subordinates if !subordinates.empty?
        # Are there any subordinate Agent roles?
        subordinates = senior_user_role.agent_subordinates
        return subordinates
      when 'Regional Distributor'
        # Are there any subordinate Agent roles?
        subordinates = senior_user_role.agent_subordinates
        return subordinates
      when 'Agent'
        # Are there any subordinate Employee roles?
        subordinates = senior_user_role.employee_subordinates
        return subordinates
      when 'Employee'
        # Are there any subordinate Player roles?
        subordinates = senior_user_role.user.employee_players
        return subordinates
      else
        return empty_list
    end
  end

  private

    def employee_cannot_be_manager
      employee_role_type = Role.find_by_name('Employee')
      return if employee_role_type.nil?   # This seems to be unavoidable when testing
      lastrole = Userrole.all.last
      return if lastrole == nil
      manager = lastrole.manager
      return if manager.nil?
      return if manager.nil?
      userroles = Userrole.where("user_id=? AND role_id=?", manager.id, employee_role_type.id)
      return if userroles == [] || userroles.count == 0
      errors.add(:manager, "An employee cannot be selected as manager")
    end

end