# frozen_string_literal: true

# Autogenerated migration to convert transfer_request_collection_transfer_requests to utf8mb4
class MigrateTransferRequestCollectionTransferRequestsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('transfer_request_collection_transfer_requests', from: 'latin1', to: 'utf8mb4')
  end
end
