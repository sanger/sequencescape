# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexAssetsOnSampleId < ActiveRecord::Migration[5.1]
  remove_index :assets, column: ['legacy_sample_id']
end
