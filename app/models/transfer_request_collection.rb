# A transfer request collection provides a means
# of bulk creating transfer requests between arbitrary
# sources and destinations.

class TransferRequestCollection < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :transfer_request_collection_transfer_requests
  has_many :transfer_requests, ->() { preload(:uuid_object, { asset: :uuid_object, target_asset: :uuid_object, submission: :uuid_object }) }, through: :transfer_request_collection_transfer_requests

  # Transfer requests themselves can go to any receptacle,
  # mostly wells and tubes. Unfortunately the current API
  # provides no effective means of handling this polymorphic
  # association elegantly, as the json root is not included in
  # a nested has_many association. This makes the handling of
  # class specific attributes, such as barcodes, a bit cumbersome,
  # especially when we are trying to eager load that information.
  has_many :target_tubes, -> { uniq }, through: :transfer_requests, source: :target_asset, class_name: 'Tube'

  belongs_to :user, required: true
  accepts_nested_attributes_for :transfer_requests
end
