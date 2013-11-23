require_relative 'location'

class Country < Location

  validate :may_not_have_a_parent

  def self.manager_names
    managers = Hash.new
    cd_role_type = Role.find_by_name('Country Distributor')
    Country.all.each do |country|
      resps = Responsibility.where("location_id=?", country.id)
      managers[country.id] = resps.first.user.name unless resps.empty?
    end
    return managers
  end

  private
  
    def may_not_have_a_parent
      #errors.add_to_base("A Country may not have a parent") unless self.parent.nil?
      errors[:base] << "A Country may not have a parent" unless self.parent.nil?
    end

end  