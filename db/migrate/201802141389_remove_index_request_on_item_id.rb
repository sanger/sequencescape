# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexRequestOnItemId < ActiveRecord::Migration[5.1]
  remove_index :requests, column: ['item_id']
end
