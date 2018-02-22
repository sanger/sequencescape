# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexItemsOnStudyId < ActiveRecord::Migration[5.1]
  remove_index :items, column: ['study_id']
end
