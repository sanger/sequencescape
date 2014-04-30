class NewPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_plate_purposes
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.destroy_plate_purposes
    end
  end

end
