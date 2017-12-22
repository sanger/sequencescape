# Remove the classes that have been migrated across
class RemoveTransferRequestsFromRequests < ActiveRecord::Migration[5.1]
  TRANSFER_REQUEST_CLASSES = [
    "TransferRequest",
    "PacBioSamplePrepRequest::Initial",
    "TransferRequest::InitialTransfer",
    "TransferRequest::InitialDownstream"
  ]

  def up
    Request.where(sti_type: TRANSFER_REQUEST_CLASSES).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
