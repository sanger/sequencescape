class AddQcPlateToLibNormPlate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_qc_plate_for('Lib Norm')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Lib Norm QC')
    end
  end
end
