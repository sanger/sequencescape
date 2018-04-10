# frozen_string_literal: true

# Foreign barcodes are stored in a separate table which joins on to
# assets.
# When the labware/receptacle split is solved, this could be
# moved onto labware, but right now it is only relevant for a
# fraction of the rows in the table.
class AddForeignBarcodesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :barcodes do |t|
      t.references :asset, type: :integer, null: false, foreign_key: true
      t.string :barcode, null: false, index: true
      t.integer :format, null: false
      t.timestamps
    end
  end
end
