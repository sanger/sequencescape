# frozen_string_literal: true

# This behaviour can be handled by the Fluidigm request class.
class DropBarcodeForTecanColumn < ActiveRecord::Migration[5.1]
  def change
    remove_column :plate_purposes, :barcode_for_tecan, :string, default: 'ean13_barcode', null: false
  end
end
