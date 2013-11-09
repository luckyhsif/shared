require_relative 'user'

class Staff < User

  def self.country_distributors 
    role = Role.find_by_name('Country Distributor')
    rlist = Responsibility.where("role_id = ?", role.id)
    cds = User.find(rlist.map(&:user_id).uniq)
  end

end