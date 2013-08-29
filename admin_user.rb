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
