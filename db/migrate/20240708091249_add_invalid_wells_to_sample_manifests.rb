# frozen_string_literal: true
class AddInvalidWellsToSampleManifests < ActiveRecord::Migration[6.1]
  def change
    add_column :sample_manifests, :invalid_wells, :text, size: :medium
  end
end