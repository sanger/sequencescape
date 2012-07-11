class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.create_plate_purposes
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.all(:conditions => { :name => IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten }).map(&:destroy)
    end
  end
end
