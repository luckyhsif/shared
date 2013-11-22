class Userrole < ActiveRecord::Base
  #self.table_name = 'userroles'
  belongs_to :user
  belongs_to :role
  belongs_to :manager, class_name: 'User'

  validate :employee_cannot_be_manager

  def self.user_role_exists?(user, role)
    ur = Userrole.where("user_id=? AND role_id=?", user.id, role.id)
    ur.count > 0
  end

  def self.find(user, role)
    ur = Userrole.where("user_id=? AND role_id=?", user.id, role.id)
    return nil if ur.empty?
    ur.first
  end

  def master_distributor_subordinates
    md_role_type = Role.find_by_name('Master Distributor')
    master_roles = Userrole.where("role_id = ? AND manager_id = ?", md_role_type.id, self.user.id)
    return master_roles
  end

  def regional_distributor_subordinates
    rd_role_type = Role.find_by_name('Regional Distributor')
    regional_roles = Userrole.where("role_id = ? AND manager_id = ?", rd_role_type.id, self.user.id)
    return regional_roles
  end

  def agent_subordinates
    agent_role_type = Role.find_by_name('Agent')
    agent_roles = Userrole.where("role_id = ? AND manager_id = ?", agent_role_type.id, self.user.id)
    return agent_roles    
  end

  def employee_subordinates
    employee_role_type = Role.find_by_name('Employee')
    employee_roles = Userrole.where("role_id = ? AND manager_id = ?", employee_role_type.id, self.user.id)
    return employee_roles
  end

  def most_senior_subordinates
    senior_role_type = self.role
    senior_user_role = self
    empty_list = []
    case senior_role_type.name
      when 'Country Distributor'
        #puts "\nRequesting the most senior subordinates of a country distributor"
        subordinates = self.master_distributor_subordinates
        #puts "The subordinates of Peter Cundis are: #{subordinates.to_json}"
        return subordinates unless subordinates.empty?
        subordinates = self.regional_distributor_subordinates
        #puts "The subordinates of Peter Cundis are: #{subordinates.to_json}"
        return subordinates unless subordinates.empty?
        subordinates = self.agent_subordinates
        #puts "The subordinates of Peter Cundis are: #{subordinates.to_json}"
        return subordinates
      when 'Master Distributor'
        #puts "\nRequesting the most senior subordinates of a master distributor"
        subordinates = self.regional_distributor_subordinates
        return subordinates unless subordinates.empty?
        subordinates = self.agent_subordinates
        return subordinates
      when 'Regional Distributor'
        #puts "\nRequesting the most senior subordinates of a regional distributor"
        subordinates = senior_user_role.agent_subordinates
        return subordinates
      when 'Agent'
        # Are there any subordinate Employee roles?
        subordinates = senior_user_role.employee_subordinates
        #puts "The subordinates of Lisa are: #{subordinates.to_json}"
        return subordinates
      when 'Employee'
        # Are there any subordinate Player roles?
        subordinates = senior_user_role.user.employee_players
        return subordinates
      else
        return empty_list
    end
  end

  def locations
    responsibilities = Responsibility.where("user_id=? AND role_id=?", self.user.id, self.role.id)
    return [] if responsibilities.empty?
    # responsibilities.each do |resp|
    #   locations << resp.location
    # end
    locations = responsibilities.map{ |resp| resp.location}
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