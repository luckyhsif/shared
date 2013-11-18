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
    #puts "Getting the most senior subordinates of user #{self.user.name} in the role of #{senior_role_type.name}"
    senior_user_role = self
    empty_list = []
    case senior_role_type.name
      when 'Country Distributor'
        #puts "\nRequesting the most senior subordinates of a country distributor"
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
        #puts "\nRequesting the most senior subordinates of a master distributor"
        # Are there any subordinate Regional Distributor roles?
        subordinates = senior_user_role.regional_distributor_subordinates
        return subordinates if !subordinates.empty?
        # Are there any subordinate Agent roles?
        subordinates = senior_user_role.agent_subordinates
        return subordinates        
        # Are there any subordinate Employee roles?
        subordinates = senior_user_role.employee_subordinates
        return subordinates
      when 'Regional Distributor'
        #puts "\nRequesting the most senior subordinates of a regional distributor"
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
      #  Uncomment this block after t.timestamps were added to userrole table
      # found = false
      # lastrole = Userrole.order("created_at").last
      # if !lastrole.manager.nil?
      #   # Find out if this manager is an employee
      #   userroles = Userrole.where("user_id=?", manager.id)
      #   userroles.each do |urole|
      #     if urole.role.name == 'Employee'
      #       found = true
      #       break
      #     end
      #   end
      # end
      # if !found
      #   lastrole = Userrole.order("updated_at").last
      #   if !lastrole.manager.nil?
      #     # Find out if this manager is an employee
      #     userroles = Userrole.where("user_id=?", manager.id)
      #     userroles.each do |urole|
      #       if urole.role.name == 'Employee'
      #         found = true
      #         break
      #       end
      #     end
      #   end
      # end
      # if found 
      #   errors.add(:manager, "An employee cannot be selected as manager")
      # end
    end

end