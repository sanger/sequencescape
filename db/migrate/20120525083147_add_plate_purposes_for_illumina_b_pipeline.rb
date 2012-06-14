class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      IlluminaBPlatePurposes.create_plate_purposes
    end
  end

  def self.down

    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE.each do |name,type|
        PlatePurpose.find_by_name(name).destroy
      end
    end

  end
end
