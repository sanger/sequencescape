# frozen_string_literal: true

# These columns are no longer needed. We rename them until we are
# sure everything is working to allow for easier rollback.
# We'll also need to migrate information across at some point soon,
# but need to get the infrastructure working first.
class RenameOldBarcodeColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :assets, :barcode, :barcode_bkp
    rename_column :assets, :barcode_prefix_id, :barcode_prefix_id_bkp
  end
end
