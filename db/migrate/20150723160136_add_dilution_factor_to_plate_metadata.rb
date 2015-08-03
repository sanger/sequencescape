class AddDilutionFactorToPlateMetadata < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_metadata, :dilution_factor, :decimal, :precision => 5, :scale => 2, :default => 1
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_metadata, :dilution_factor
    end
  end
end
