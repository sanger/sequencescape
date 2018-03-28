# Remove hardcoded barcode prefix ids from plate purposes.
class AddBarcodePrefixIdToPlatePurposes < ActiveRecord::Migration[4.2]
  def change
    add_reference :plate_purposes, :barcode_prefix, foreign_key: true
  end
end
