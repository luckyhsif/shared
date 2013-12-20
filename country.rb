require_relative 'location'

class Country < Location

  validate :may_not_have_a_parent
  belongs_to :currency
  has_many :users

  def self.list(offset=0, limit=0)
    total_countries = Country.all.count
    calculated_offset = offset * limit
    sqlstr = "SELECT * FROM locations L"  \
      " WHERE L.type = 'Country'" \
      " ORDER BY L.name LIMIT #{limit} OFFSET #{calculated_offset}" 
    countries = Location.find_by_sql [sqlstr]
    results = [countries, total_countries]
  end

  def self.country_managers
    managers = Hash.new
    cd_role_type = Role.find_by_name('Country Distributor')
    Country.all.each do |country|
      resps = Responsibility.where("location_id=?", country.id)
      managers[country.id] = resps.first.user unless resps.empty?
    end
    return managers
  end

  def self.button_label
    t.location.country.add
  end

  def self.buttons_for_children_list
    return 't.location.masterregion.add'
  end

  def managers_for_sublocations  # print this
    managers = Hash.new
    md_role_type = Role.find_by_name('Master Distributor')
    self.children.each do |masterregion|
      resps = Responsibility.where("location_id=? AND role_id=?", masterregion.id, md_role_type.id)
      managers[resps.first.location.id] = resps.first.user unless resps.empty?
    end
    return managers
  end

  def self.unmanaged_countries
    countries = []
    Country.all.each do |country| 
      resps = Responsibility.where("location_id=?", country.id)
      countries << country if resps.empty?
    end 
    return countries if countries.empty?
    countries.sort! { |a,b| a.name <=> b.name }
    return countries
  end

  private
  
    def may_not_have_a_parent
      #errors.add_to_base("A Country may not have a parent") unless self.parent.nil?
      errors[:base] << "A Country may not have a parent" unless self.parent.nil?
    end

end  