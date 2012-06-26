class RemoveRedundantDilutionPlateCreators < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Plate::Creator.find_by_name('Dilution Plates').destroy
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      plate_creator = Plate::Creator.create!(
      :name => 'Dilution Plates',
      :plate_purpose => PlatePurpose.find_by_name('Dilution Plates')
      )
      plate_creator.plate_purposes << PlatePurpose.find_by_name('Working Dilution') << PlatePurpose.find_by_name('Pico Dilution')
    end
  end
end
