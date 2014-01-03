class Responsibility < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :location

  def self.find_responsibility_for_location(userid, locid)
    resps = Responsibility.where("user_id=? AND location_id=?", userid, locid)
    return nil if resps.empty?
    resps.first
  end

  def can_be_removed?
    return true if self.user.is_employee?
    if self.user.is_agent?
      employees, total = self.user.agent_employees
      return false if total > 0
      players, total = self.user.agent_players
      return false if total > 0
      return true
    end
    child_locations = self.location.children
    return true if child_locations.nil?
    return true if self.user.immediate_subordinates.nil?
    # Consider one location for which each immediate subordinate is responsible
    self.user.immediate_subordinates.each do |sub|
      # Is this subordinate responsible for a child location of self.location?
      rlist = Responsibility.where("user_id=?", sub.id)
      return false if (!rlist.empty? && child_locations.include?(rlist.first.location))
    end
    return true   
  end
end
