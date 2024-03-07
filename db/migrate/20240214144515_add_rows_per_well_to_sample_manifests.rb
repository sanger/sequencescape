# frozen_string_literal: true
class AddRowsPerWellToSampleManifests < ActiveRecord::Migration[6.0]
  def change
    add_column :sample_manifests, :rows_per_well, :integer
  end
end
