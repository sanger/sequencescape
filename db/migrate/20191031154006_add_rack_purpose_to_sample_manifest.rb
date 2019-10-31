class AddRackPurposeToSampleManifest < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_manifests, :tube_rack_purpose_id, :integer
  end
end
