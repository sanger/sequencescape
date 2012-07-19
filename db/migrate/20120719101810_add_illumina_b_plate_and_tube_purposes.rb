class AddIlluminaBPlateAndTubePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.create_tube_purposes
      IlluminaB::PlatePurposes.create_plate_purposes
      IlluminaB::PlatePurposes.create_branches
    end
  end

  def self.down
  end
end
