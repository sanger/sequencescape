# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexPipelinesOnSorter < ActiveRecord::Migration[5.1]
  remove_index :pipelines, column: ['sorter']
end
