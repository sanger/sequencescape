# A transfer request collection provides a means
# of bulk creating transfer requests between arbitrary
# sources and destinations.

class TransferRequestCollection < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :transfer_request_collection_transfer_requests
  has_many :transfer_requests, through: :transfer_request_collection_transfer_requests
  belongs_to :user, required: true
  accepts_nested_attributes_for :transfer_requests
end
