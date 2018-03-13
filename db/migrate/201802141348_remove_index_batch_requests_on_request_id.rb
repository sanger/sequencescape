# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBatchRequestsOnRequestId < ActiveRecord::Migration[5.1]
  remove_index :batch_requests, column: ['request_id'], name: 'index_batch_requests_on_request_id'
end
