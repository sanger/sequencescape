#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSizeAndShapeToPlatePurpose < ActiveRecord::Migration
  def self.up
    default = AssetShape.find_by_name('Standard').id
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :size, :integer, :default=>96, :null=>true
      add_column :plate_purposes, :asset_shape_id, :integer, :default=>default, :null=>false
      Purpose.reset_column_information
      Purpose.find_by_name('Sequenom').update_attributes!(:size=>384)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :size
      remove_column :plate_purposes, :asset_shape_id
    end
  end
end
