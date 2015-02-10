#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPlateShapeTable < ActiveRecord::Migration
  def self.up
    create_table :asset_shapes do |t|
      t.string 'name', :null => false
      t.integer 'horizontal_ratio', :null => false
      t.integer 'vertical_ratio', :null => false
      t.string  'description_strategy', :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :asset_shapes
  end
end
