# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBillingEventsOnKind < ActiveRecord::Migration[5.1]
  remove_index :billing_events, column: ['kind']
end
