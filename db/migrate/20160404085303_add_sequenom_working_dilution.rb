class AddSequenomWorkingDilution < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      plate_purpose = DilutionPlatePurpose.create!(:name => 'Agena Working Dilution', :target_type => WorkingDilutionPlate.name)

      creator = Plate::Creator.create!(:name => 'Agena Working Dilution', :plate_purpose => plate_purpose, :plate_purposes => [ plate_purpose ],
        :valid_options => {:valid_dilution_factors => [12.5,20.0,15.0,50.0]} )

      Plate::Creator.find_by_name!("Pico dilution").parent_plate_purposes << plate_purpose
    end
  end

  def down
    ActiveRecord::Base.transaction do
      plate_purpose = DilutionPlatePurpose.find_by_name!('Agena Working Dilution')
      #Purpose::Relationship.select{|r| r.parent == plate_purpose}.each(&:destroy!)
      Plate::Creator.find_by_name!(plate_purpose.name).destroy
      plate_purpose.destroy
    end
  end
end
