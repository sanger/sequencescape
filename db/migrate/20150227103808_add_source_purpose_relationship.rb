class AddSourcePurposeRelationship < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :source_purpose_id, :integer
  end

  def self.down
    add_column :plate_purposes, :source_purpose_id
  end
end
