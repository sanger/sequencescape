# frozen_string_literal: true

# Just a simple join table
class TransferRequestCollectionTransferRequest < ApplicationRecord
  belongs_to :transfer_request_collection, required: true
  belongs_to :transfer_request, required: true
end
