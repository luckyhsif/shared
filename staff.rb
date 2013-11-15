require_relative 'user'

class Staff < User

  def self.country_distributors 
    role = Role.find_by_name('Country Distributor')
    #rlist = Responsibility.where("role_id = ?", role.id)
    rlist = Userrole.where("role_id = ?", role.id)
    return nil if rlist.empty?
    cds = User.find(rlist.map(&:user_id).uniq)
  end

  def self.country_distributor_roles
    cntr_role_type = Role.find_by_name('Country Distributor')
    rlist = Userrole.where("role_id = ?", cntr_role_type.id)
  end

end