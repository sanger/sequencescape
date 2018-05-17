# frozen_string_literal: true

# Rename the old columns to avoid confusion, we can strip them out
# entirely once we're confident everything is working.
class RenameOldMetadataColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :plate_metadata, :infinium_barcode, :infinium_barcode_bkp
    rename_column :plate_metadata, :fluidigm_barcode, :fluidigm_barcode_bkp
  end
end
