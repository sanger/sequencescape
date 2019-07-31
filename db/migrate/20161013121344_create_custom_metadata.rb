# Rails migration
class CreateCustomMetadata < ActiveRecord::Migration
  def change
    create_table :custom_metadata do |t|
      t.string :key
      t.string :value
      t.references :custom_metadatum_collection

      t.timestamps
    end
    add_index :custom_metadata, :custom_metadatum_collection_id
  end
end
