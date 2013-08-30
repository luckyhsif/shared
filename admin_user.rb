class AdminUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

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

