class Responsibility < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :location

  def self.find_responsibility_for_location(userid, locid)
    resps = Responsibility.where("user_id=? AND location_id=?", userid, locid)
    return nil if resps.empty?
    resps.first
  end
end
