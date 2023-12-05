class CreatePolyMetadata < ActiveRecord::Migration[6.0]
  def change
    create_table :poly_metadata do |t|
      t.string :key
      t.string :value
      t.references :metadatable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
