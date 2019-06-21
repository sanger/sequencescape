# frozen_string_literal: true

# Ensure barcodes points at labware, not assets
class UpdateQcFilesForeignKey < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :qc_files, column: :asset_id
    add_foreign_key :qc_files, :labware, column: :asset_id
  end
end
