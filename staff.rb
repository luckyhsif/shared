require_relative 'user'

class Staff < User

  def self.country_distributors 
    role = Role.find_by_name('Country Distributor')
    rlist = Userrole.where("role_id = ?", role.id)
    return nil if rlist.empty?
    cds = User.find(rlist.map(&:user_id).uniq)
  end

  def self.country_distributor_roles(offset=0, limit=0)
    cd_role_type = Role.find_by_name('Country Distributor')
    #rlist = Userrole.where("role_id = ?", cntr_role_type.id)
    cd_roles_ids = "SELECT U.id FROM userroles UR" \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{cd_role_type.id}" 
    total = (Userrole.find_by_sql [cd_roles_ids]).count
    calculated_offset = offset * limit
    sqlstr = "SELECT UR.* FROM userroles UR"  \
      " LEFT OUTER JOIN users U ON UR.user_id = U.id" \
      " LEFT OUTER JOIN roles ON UR.role_id = roles.id" \
      " WHERE roles.id = #{cd_role_type.id}" \
      " ORDER BY U.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    rd_roles = Userrole.find_by_sql [sqlstr]
    results = [rd_roles, total]
  end

end