# frozen_string_literal: true

# add long read pipelines to sample metadata.
class AddLongReadPipelinesToSampleMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_metadata, :saphyr, :string
    add_column :sample_metadata, :pacbio, :string
  end
end
