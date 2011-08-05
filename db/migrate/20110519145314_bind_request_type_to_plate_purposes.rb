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
