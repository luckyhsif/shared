class Permission < ActiveRecord::Base
  has_and_belongs_to_many :users, association_foreign_key: :user_id
  has_many :permission_rules     #, inverse_of: :permission
  validates :name,  :presence   => true, 
                    :length     => { :minimum => 5, :maximum => 50 }, 
                    :uniqueness => { :case_sensitive => false }
end
