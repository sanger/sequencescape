# frozen_string_literal: true
# Directly associate manifests with their assets no samples are no longer created upfront
class AddSampleManifestAssetTable < ActiveRecord::Migration[5.1]
  def change
    create_table :sample_manifest_assets do |t|
      t.belongs_to :sample_manifest, index: true
      t.belongs_to :asset, index: true
      t.string :sanger_sample_id
      t.timestamps
    end
    add_index :sample_manifest_assets, :sanger_sample_id
  end
end
