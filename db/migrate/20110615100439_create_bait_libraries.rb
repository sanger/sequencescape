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
