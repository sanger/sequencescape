# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexAttemptsOnRequestId < ActiveRecord::Migration[5.1]
  remove_index :depricated_attempts, column: ['request_id']
end
