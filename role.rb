class Role < ActiveRecord::Base
  has_one :parent, class_name: 'Role', foreign_key: :parent_id
  has_many :permission_rules
  validates :name, :presence   => true,
                   :uniqueness => { :case_sensitive => false }
  has_many :responsibilities

  def is_senior_to?(role)
    while role.parent != nil
      
    end
  end
end