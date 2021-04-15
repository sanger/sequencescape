# frozen_string_literal: true

# sample_reference_genome_old is a hang over from before reference genome names were migrated into their own table
# it was supposed to be removed but it never happened (until now)
class RemoveSampleReferenceGenomeOldFromSampleMetadata < ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_metadata, :sample_reference_genome_old, :string
  end
end
