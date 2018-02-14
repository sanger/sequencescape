# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexSampleManifestsOnCreatedAt < ActiveRecord::Migration[5.1]
  remove_index :sample_manifests, column: ['created_at']
end
