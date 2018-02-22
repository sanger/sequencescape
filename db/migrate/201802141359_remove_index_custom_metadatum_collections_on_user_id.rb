# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexCustomMetadatumCollectionsOnUserId < ActiveRecord::Migration[5.1]
  remove_index :custom_metadatum_collections, column: ['user_id']
end
