class AddIlluminaBQcPlates < ActiveRecord::Migration
  include IlluminaB::PlatePurposes

  def self.up
    IlluminaB::PlatePurposes.create_qc_plates
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
        PlatePurpose.find_by_name("#{name} QC").destroy
      end
    end
  end
end
