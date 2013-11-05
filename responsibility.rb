class Responsibility < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :location
  belongs_to :manager, class_name: 'User'

  validate :employee_cannot_be_manager

  private

    def employee_cannot_be_manager
      r = Responsibility.last
      return if r == nil
      # Find the manager of this responsibility
      # Find out if this user is an employee
      user = r.manager
      return if user == nil
      rs = Responsibility.where("user_id=?", user.id)
      return if rs.count == 0
      rs.each do |r|
        if r.role.name == 'Employee'
          errors.add(:manager, "An employee cannot be selected as manager")
          break
        end
      end
    end

end
