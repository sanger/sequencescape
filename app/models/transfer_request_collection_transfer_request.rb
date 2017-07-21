# Just a simple join table
class TransferRequestCollectionTransferRequest < ActiveRecord::Base
  belongs_to :transfer_request_collection, required: true
  belongs_to :transfer_request, required: true
end
