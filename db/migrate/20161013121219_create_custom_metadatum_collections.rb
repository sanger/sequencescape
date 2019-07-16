# Rails migration
class CreateCustomMetadatumCollections < ActiveRecord::Migration
  def change
    create_table :custom_metadatum_collections do |t|
      t.references :user
      t.references :asset

      t.timestamps
    end
    add_index :custom_metadatum_collections, :user_id
    add_index :custom_metadatum_collections, :asset_id
  end
end
