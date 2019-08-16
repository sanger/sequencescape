# frozen_string_literal: true

# StudyMetadata and SampleMetadata are the two primary sticking points when
# it comes to encoding issues, so we update them first. I'm converting the whole
# table here as no sting/text columns are indexed.
class MigrateSampleMetadataToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('sample_metadata', from: 'latin1', to: 'utf8mb4')
  end
end
