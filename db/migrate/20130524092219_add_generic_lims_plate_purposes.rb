class AddGenericLimsPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaC::PlatePurposes.create_plate_purposes
      IlluminaC::PlatePurposes.create_tube_purposes
      IlluminaC::PlatePurposes.create_branches
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaC::PlatePurposes.destroy_plate_purposes
      IlluminaC::PlatePurposes.destroy_tube_purposes
    end
  end
end
