# frozen_string_literal: true

# The foreign key should now point at the transfer_requests table, not requests.
class UpdateFkAssociationInTransferRequestCollection < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :transfer_request_collection_transfer_requests, column: :transfer_request_id
    add_foreign_key :transfer_request_collection_transfer_requests, :transfer_requests
  end

  def down
    remove_foreign_key :transfer_request_collections_transfer_requests, :transfer_requests
    add_foreign_key :transfer_request_collections_transfer_requests, :requests, column: :transfer_request_id
  end
end
