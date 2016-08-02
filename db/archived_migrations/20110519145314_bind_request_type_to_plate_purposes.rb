#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class BindRequestTypeToPlatePurposes < ActiveRecord::Migration
  def self.up
    create_table :request_type_plate_purposes do |t|
      t.references :request_type, :null => false
      t.references :plate_purpose, :null => false
    end

    add_index :request_type_plate_purposes, [ :request_type_id, :plate_purpose_id ], :unique => true, :name => 'plate_purposes_are_unique_within_request_type'
  end

  def self.down
    drop_table :request_type_plate_purposes
  end
end
