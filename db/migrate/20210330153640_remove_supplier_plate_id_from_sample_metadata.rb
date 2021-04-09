# frozen_string_literal: true

# supplier_plate_id has been around for 10 years, has no data, and isn't available in the manifests
class RemoveSupplierPlateIdFromSampleMetadata < ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_metadata, :supplier_plate_id, :string
  end
end
