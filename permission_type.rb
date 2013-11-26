class PermissionType < ActiveRecord::Base
  has_many :permissions, foreign_key: :permission_type_id
  validates :name,  :presence   => true, 
                    :length     => { :minimum => 5, :maximum => 50 }, 
                    :uniqueness => { :case_sensitive => false }

end
