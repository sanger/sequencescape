# Remove the request_types associated with transfer requests
class RemoveRedundantRequestTypes < ActiveRecord::Migration[5.1]
  TRANSFER_REQUEST_CLASSES = [
    'TransferRequest',
    'PacBioSamplePrepRequest::Initial',
    'TransferRequest::InitialTransfer',
    'TransferRequest::InitialDownstream'
  ]

  def up
    RequestType.where(request_class_name: TRANSFER_REQUEST_CLASSES).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
