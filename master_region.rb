require_relative 'location'

class MasterRegion < Location

  def managers_for_sublocations
    managers = Hash.new
    rd_role_type = Role.find_by_name('Regional Distributor')
    self.children.each do |region|
      resps = Responsibility.where("location_id=? AND role_id=?", region.id, rd_role_type.id)
      managers[resps.first.location.id] = resps.first.user unless resps.empty?
    end
    return managers
  end

  def self.title_for_lists
    return 't.location.master.plural'
  end

  def self.title_for_location_names
    return 't.location.master.location_heading'
  end

  def self.title_for_managers
    return 't.location.master.manager_heading'
  end

  def self.buttons_for_children_list
    return 't.location.region.add'
  end

end