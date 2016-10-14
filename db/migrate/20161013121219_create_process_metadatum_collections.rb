class CreateProcessMetadatumCollections < ActiveRecord::Migration
  def change
    create_table :process_metadatum_collections do |t|
      t.references :user
      t.references :asset

      t.timestamps
    end
    add_index :process_metadatum_collections, :user_id
    add_index :process_metadatum_collections, :asset_id
  end
end
