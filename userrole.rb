class Userrole < ActiveRecord::Base
  #self.table_name = 'userroles'
  belongs_to :user
  belongs_to :role
  belongs_to :manager, class_name: 'User'

end