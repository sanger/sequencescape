#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddPlateConversionTables < ActiveRecord::Migration
  def self.up
    create_table 'plate_conversions' do |t|
      t.references :target,  :null => false
      t.references :purpose, :null => false
      t.references :user,    :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table 'plate_conversions'
  end
end
