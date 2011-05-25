class CreatePlatePurposeRelationships < ActiveRecord::Migration
  def self.up
    create_table :plate_purpose_relationships do |t|
      t.references :parent
      t.references :child
    end
  end

  def self.down
    drop_table :plate_purpose_relationships
  end
end
