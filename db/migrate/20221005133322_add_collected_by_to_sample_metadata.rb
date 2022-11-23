# frozen_string_literal: true

# Adds the column: collected_by, to the sample_metadata table
# To allow for manifests uploading samples from multiple collection sites
class AddCollectedByToSampleMetadata < ActiveRecord::Migration[6.0]
  def change
    add_column :sample_metadata,
               :collected_by,
               :string,
               comment: 'Name of persons or institute who collected the specimen'
  end
end
