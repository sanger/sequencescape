# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexEventsOnFamily < ActiveRecord::Migration[5.1]
  remove_index :events, column: ['family']
end
