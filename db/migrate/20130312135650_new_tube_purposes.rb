class NewTubePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_tube_purposes
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.destroy_tube_purposes
    end
  end

end
