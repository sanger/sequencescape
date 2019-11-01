# frozen_string_literal: true

# Add association to link Sample Manifest table with TubeRack::Purpose
class AddTubeRackPurposeToSampleManifest < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_manifests, :tube_rack_purpose_id, :integer
  end
end
