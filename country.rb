require_relative 'location'

class Country < Location

  validate :may_not_have_a_parent

  private
  
    def may_not_have_a_parent
      #errors.add_to_base("A Country may not have a parent") unless self.parent.nil?
      errors[:base] << "A Country may not have a parent" unless self.parent.nil?
    end

end  