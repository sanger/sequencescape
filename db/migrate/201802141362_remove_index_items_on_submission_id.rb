# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexItemsOnSubmissionId < ActiveRecord::Migration[5.1]
  remove_index :items, column: ['submission_id']
end
