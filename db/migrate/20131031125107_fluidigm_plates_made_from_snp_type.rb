class FluidigmPlatesMadeFromSnpType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by_key('pick_to_fluidigm')
      rt.acceptable_plate_purposes.clear
      rt.acceptable_plate_purposes << PlatePurpose.find_by_name('SNP Type')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by_key('pick_to_fluidigm')
      rt.acceptable_plate_purposes.clear
      rt.acceptable_plate_purposes << PlatePurpose.find_by_name('STA2')
    end
  end
end
