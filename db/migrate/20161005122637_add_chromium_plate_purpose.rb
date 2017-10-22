class AddChromiumPlatePurpose < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      stock_plate = Purpose.find_by!(name: 'ILC Stock')
      library_creation_freezer = Location.find_by(name: 'Library creation freezer')
      IlluminaC::PlatePurposes.create_plate_purpose('ILC Lib Chromium', default_location: library_creation_freezer, source_purpose_id: stock_plate.id)
      IlluminaC::PlatePurposes.create_branch(['ILC Stock', 'ILC Lib Chromium', 'ILC Lib Pool Norm'])
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Purpose.find_by(name: 'ILC Lib Chromium').destroy
    end
  end
end
