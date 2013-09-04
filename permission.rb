class Permission < ActiveRecord::Base
  has_and_belongs_to_many :users, association_foreign_key: :user_id
  validates_uniqueness_of :name
 
end
