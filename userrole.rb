class Userrole < ActiveRecord::Base
  #self.table_name = 'userroles'
  belongs_to :user     #, class_name: 'User', primary_key: user_id
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

  def self.all_master_distributors(offset=0, limit=0)
    md_role_type = Role.find_by_name('Master Distributor')
    #master_roles = Userrole.where("role_id = ?", md_role_type.id)
    master_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{md_role_type.id}"
    total = (Userrole.find_by_sql [master_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{md_role_type.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    master_roles = Userrole.find_by_sql [sqlstr]
    results = [master_roles, total]
  end

  def self.all_regional_distributors(offset=0, limit=0)
    rd_role_type = Role.find_by_name('Regional Distributor')
    #rd_roles = Userrole.where("role_id = ?", rd_role_type.id)
    rd_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{rd_role_type.id}"
    total = (Userrole.find_by_sql [rd_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{rd_role_type.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    rd_roles = Userrole.find_by_sql [sqlstr]
    results = [rd_roles, total]
  end

  def self.all_agents(offset=0, limit=0)
    #puts "\Entering self.all_agents"
    agent_role_type = Role.find_by_name('Agent')
    #agent_roles = Userrole.where("role_id = ?", agent_role_type.id)
    agent_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{agent_role_type.id}"
    total = (Userrole.find_by_sql [agent_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{agent_role_type.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    agent_roles = Userrole.find_by_sql [sqlstr]
    results = [agent_roles, total]
  end

  def self.all_employees(offset=0, limit=0)
    employee_role_type = Role.find_by_name('Employee')
    #agent_roles = Userrole.where("role_id = ?", agent_role_type.id)
    employee_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{employee_role_type.id}"
    total = (Userrole.find_by_sql [employee_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    employee_roles = Userrole.find_by_sql [sqlstr]
    puts "\nself.all_employees"
    puts "Total employees: #{total}"
    employee_roles.map { |erole| puts erole.user.name }
    results = [employee_roles, total]
  end

  def master_distributor_subordinates(offset=0, limit=0)
    #puts "\nEntering master_distributor_subordinates"
    md_role_type = Role.find_by_name('Master Distributor')
    #    master_roles = Userrole.where("role_id = ? AND manager_id = ?", md_role_type.id, self.user.id)
    master_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{md_role_type.id}" \
      " AND UR.manager_id = #{self.user.id}"
    total = (Userrole.find_by_sql [master_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{md_role_type.id}" \
      " AND Manager.id = #{self.user.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    master_roles = Userrole.find_by_sql [sqlstr]
    results = [master_roles, total]
  end

  def regional_distributor_subordinates(offset=0, limit=0)
    #puts "\nEntering regional_distributor_subordinates"
    rd_role_type = Role.find_by_name('Regional Distributor')
    #regional_roles = Userrole.where("role_id = ? AND manager_id = ?", rd_role_type.id, self.user.id)
    rd_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{rd_role_type.id}" \
      " AND UR.manager_id = #{self.user.id}"
    total = (Userrole.find_by_sql [rd_roles_ids]).count
    #puts "regional_distributor_subordinates - total recs found: #{total.to_s}"
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{rd_role_type.id}" \
      " AND Manager.id = #{self.user.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    rd_roles = Userrole.find_by_sql [sqlstr]
    results = [rd_roles, total]
  end

  def agent_subordinates(offset=0, limit=0)
    #puts "\nEntering agent_subordinates"
    agent_role_type = Role.find_by_name('Agent')
    #agent_roles = Userrole.where("role_id = ? AND manager_id = ?", agent_role_type.id, self.user.id)
    agent_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{agent_role_type.id}" \
      " AND UR.manager_id = #{self.user.id}"
    total = (Userrole.find_by_sql [agent_roles_ids]).count
    #puts "agent_subordinates - total recs found: #{total.to_s}"
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{agent_role_type.id}" \
      " AND Manager.id = #{self.user.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    agent_roles = Userrole.find_by_sql [sqlstr]
    results = [agent_roles, total]
  end

  def employee_subordinates(offset=0, limit=0)
    employee_role_type = Role.find_by_name('Employee')
    #employee_roles = Userrole.where("role_id = ? AND manager_id = ?", employee_role_type.id, self.user.id)
    employee_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND UR.manager_id = #{self.user.id}"
    total = (Userrole.find_by_sql [employee_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " LEFT OUTER JOIN users Manager ON UR.manager_id = Manager.id" \
      " WHERE roles.id = #{employee_role_type.id}" \
      " AND Manager.id = #{self.user.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    employee_roles = Userrole.find_by_sql [sqlstr]
    results = [employee_roles, total]
  end

  def most_senior_subordinates(offset=0, limit=0)
    senior_role_type = self.role
    senior_user_role = self
    empty_list = []
    case senior_role_type.name
      when 'Country Distributor'
        subordinates = self.master_distributor_subordinates(offset, limit)
        return subordinates unless subordinates.empty?
        subordinates = self.regional_distributor_subordinates(offset, limit)
        return subordinates unless subordinates.empty?
        subordinates = self.agent_subordinates(offset, limit)
        return subordinates
      when 'Master Distributor'
        subordinates = self.regional_distributor_subordinates(offset, limit)
        return subordinates unless subordinates.empty?
        subordinates = self.agent_subordinates(offset, limit)
        return subordinates
      when 'Regional Distributor'
        subordinates = senior_user_role.agent_subordinates(offset, limit)
        return subordinates
      when 'Agent'
        subordinates = senior_user_role.employee_subordinates(offset, limit)
        return subordinates
      when 'Employee'
        subordinates = senior_user_role.user.employee_players(offset, limit)
        return subordinates
      else
        return empty_list
    end
  end

  def locations(offset=0, limit=0)
    #responsibilities = Responsibility.where("user_id=? AND role_id=?", self.user.id, self.role.id)
    loc_ids = "SELECT L.id FROM responsibilities RE" \
      " LEFT OUTER JOIN users U ON RE.user_id = U.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " WHERE RE.role_id = #{self.role.id}"
      " AND RE.user_id = #{self.user.id}"
    total = (User.find_by_sql [loc_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT L.* FROM responsibilities RE" \
      " LEFT OUTER JOIN users U ON RE.user_id = U.id" \
      " LEFT OUTER JOIN locations L ON RE.location_id = L.id" \
      " WHERE RE.role_id = #{self.role.id}"
      " AND RE.user_id = #{self.user.id}"
      " ORDER BY L.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    locations = Userrole.find_by_sql [sqlstr]
    results = [locations, total]
  end

  def managers_per_location
    managers = Hash.new
    responsibilities = Responsibility.where("user_id=? AND role_id=?", self.user.id, self.role.id)
    return [] if responsibilities.empty?
    responsibilities.each do |resp|
      managers[resp.location.id] = resp.user
    end
    return managers
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