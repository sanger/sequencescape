# frozen_string_literal: true

# Just a simple join table
class TransferRequestCollectionTransferRequest < ApplicationRecord
  belongs_to :transfer_request_collection, optional: false
  belongs_to :transfer_request, optional: false
end
