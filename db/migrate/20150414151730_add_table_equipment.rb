#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddTableEquipment < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :equipment do |t|
        t.string :name
        t.string :equipment_type
        t.string :prefix, :limit => 2, :null => false
        t.string :ean13_barcode, :limit => 13
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :equipment
    end
  end
end
