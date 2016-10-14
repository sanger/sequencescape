class CreateProcessMetadata < ActiveRecord::Migration
  def change
    create_table :process_metadata do |t|
      t.string :key
      t.string :value
      t.references :process_metadatum_collection

      t.timestamps
    end
    add_index :process_metadata, :process_metadatum_collection_id
  end
end
