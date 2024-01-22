# frozen_string_literal: true
#
# Add polymorphic metadata table to flexibly hold key value pairs
class CreatePolyMetadata < ActiveRecord::Migration[6.0]
  def change
    create_table :poly_metadata do |t|
      t.string :key, null: false
      t.string :value, null: false
      t.references :metadatable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
