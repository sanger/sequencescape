# frozen_string_literal: true

# Add Genome size to sample metadata
class AddGenomeSizeToSampleMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_metadata, :genome_size, :integer
  end
end
