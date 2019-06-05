# frozen_string_literal: true

# Ensure barcodes points at labware, not assets
class UpdateBarcodeForeignKey < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :barcodes, column: :asset_id
    add_foreign_key :barcodes, :labware, column: :asset_id
  end
end
