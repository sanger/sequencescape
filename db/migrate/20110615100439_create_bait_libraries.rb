#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateBaitLibraries < ActiveRecord::Migration
  def self.up
    create_table :bait_library_suppliers do |t|
      t.string :name, :null => false
      t.timestamps
    end

    add_index :bait_library_suppliers, :name, :unique => true

    create_table :bait_libraries do |t|
      t.references :bait_library_supplier
      t.string :name,               :null => false
      t.string :supplier_identifier
      t.string :target_species,     :null => false
      t.timestamps
    end

    add_index :bait_libraries, [ :bait_library_supplier_id, :name ], :unique => true, :name => 'bait_library_names_are_unique_within_a_supplier'
  end

  def self.down
    drop_table :bait_libraries
    drop_table :bait_library_suppliers
  end
end
