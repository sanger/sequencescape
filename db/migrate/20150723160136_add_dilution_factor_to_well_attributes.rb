class AddDilutionFactorToWellAttributes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :well_attributes, :dilution_factor, :integer
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :well_attributes, :dilution_factor
    end
  end
end
