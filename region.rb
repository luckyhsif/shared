require_relative 'location'

class Region < Location

  def managers_for_sublocations
    managers = Hash.new
    agent_role_type = Role.find_by_name('Agent')
    self.children.each do |agent|
      resps = Responsibility.where("location_id=? AND role_id=?", agent.id, agent_role_type.id)
      managers[resps.first.location.id] = resps.first.user unless resps.empty?
    end
    return managers
  end

  def self.title_for_lists
    return 't.location.region.plural'
  end

  def self.title_for_location_names
    return 't.location.region.location_heading'
  end

  def self.title_for_managers
    return 't.location.region.manager_heading'
  end

  def self.buttons_for_children_list
    return 't.location.venue.add'
  end

end