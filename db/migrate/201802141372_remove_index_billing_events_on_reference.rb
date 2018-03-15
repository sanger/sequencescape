# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBillingEventsOnReference < ActiveRecord::Migration[5.1]
  remove_index :billing_events, column: ['reference']
end
