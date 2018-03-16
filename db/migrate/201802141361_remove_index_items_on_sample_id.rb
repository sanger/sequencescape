# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexItemsOnSampleId < ActiveRecord::Migration[5.1]
  remove_index :items, column: ['workflow_sample_id']
end
