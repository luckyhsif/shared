class Userrole < ActiveRecord::Base
  #self.table_name = 'userroles'
  belongs_to :user
  belongs_to :role
  belongs_to :manager, class_name: 'User'

  validate :employee_cannot_be_manager


  private

    def employee_cannot_be_manager
      employee_role_type = Role.find_by_name('Employee')
      return if employee_role_type.nil?   # This seems to be unavoidable when testing
      lastrole = Userrole.all.last
      return if lastrole == nil
      manager = lastrole.manager
      return if manager.nil?
      return if manager.nil?
      userroles = Userrole.where("user_id=? AND role_id=?", manager.id, employee_role_type.id)
      return if userroles == [] || userroles.count == 0
      errors.add(:manager, "An employee cannot be selected as manager")
    end

end