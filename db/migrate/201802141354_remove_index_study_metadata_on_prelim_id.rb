# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexStudyMetadataOnPrelimId < ActiveRecord::Migration[5.1]
  remove_index :study_metadata, column: ['prelim_id']
end
