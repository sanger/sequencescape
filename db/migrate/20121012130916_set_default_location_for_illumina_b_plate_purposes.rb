class SetDefaultLocationForIlluminaBPlatePurposes < ActiveRecord::Migration
  class Location < ActiveRecord::Base
    set_table_name('locations')
  end

  class Purpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)
  end

  def self.up
    ActiveRecord::Base.transaction do
      location = Location.find_by_name('Library creation freezer') or raise "Cannot find library creation freezer"
      Purpose.find_each(:conditions => 'name LIKE "ILB_STD_%" AND name!="ILB_STD_INPUT"') do |purpose|
        purpose.update_attributes!(:default_location_id => location.id)
      end
    end
  end

  def self.down
    # Nothing to do as this gets dropped later
  end
end
