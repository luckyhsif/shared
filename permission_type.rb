class PermissionType < ActiveRecord::Base
  has_many :permissions
  validates :name,  :presence   => true, 
                    :length     => { :minimum => 5, :maximum => 50 }, 
                    :uniqueness => { :case_sensitive => false }

end
