class AdminUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable
  
  has_and_belongs_to_many :permissions, foreign_key: :user_id
  has_and_belongs_to_many :received_messages, class_name: 'Message', foreign_key: :recipient_id
  has_many :messages, foreign_key: :sender_id

  def is_allowed?(perm_name)
    p = Permission.find_by_name(perm_name)
    return false if p.nil?
    # huh? http://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-include-3F
    # TODO: find out why this is returning a '1' or nil, not true or false.
    return !self.permissions.include?(p).nil?
  end

end

class Player < AdminUser
  belongs_to :location
end

class Employee < AdminUser
  belongs_to :location
end

class Agent < AdminUser
  belongs_to :location
end

class RegionalDistributor < AdminUser
  has_many :locations, inverse_of: :regional_distributor
end

class MasterDistributor < AdminUser
  has_many :locations, inverse_of: :master_distributor
end

class CountryDistributor < AdminUser
  has_many :locations, inverse_of: :country_distributor
end

