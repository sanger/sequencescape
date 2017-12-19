# A transfer request collection provides a means
# of bulk creating transfer requests between arbitrary
# sources and destinations.

class TransferRequestCollection < ApplicationRecord
  include Uuid::Uuidable

  has_many :transfer_request_collection_transfer_requests
  has_many :transfer_requests, ->() { preload(:uuid_object, asset: :uuid_object, target_asset: :uuid_object, submission: :uuid_object) }, through: :transfer_request_collection_transfer_requests

  # Transfer requests themselves can go to any receptacle,
  # mostly wells and tubes. Unfortunately the current API
  # provides no effective means of handling this polymorphic
  # association elegantly, as the json root is not included in
  # a nested has_many association. This makes the handling of
  # class specific attributes, such as barcodes, a bit cumbersome,
  # especially when we are trying to eager load that information.
  has_many :target_tubes, -> { distinct }, through: :transfer_requests, source: :target_asset, class_name: 'Tube'

  belongs_to :user, required: true
  accepts_nested_attributes_for :transfer_requests

  # These are optimizations to reduce the number of queries that need to be
  # performed while the transfer takes place.
  # Transfer requests rely both on the aliquots in an assets, and the transfer rquests
  # into the asset (used to track state). Here we eager load all necessary assets
  # and associated records, and pass them to the transfer requests directly.
  def transfer_requests_attributes=(args)
    asset_ids = extract_asset_ids(args)
    asset_cache = Asset.includes(:aliquots, :transfer_requests).find(asset_ids).index_by(&:id)
    optimized_parameters = args.map do |param|
      param.stringify_keys!
      param['asset'] ||= asset_cache[param['asset_id']]
      param['target_asset'] ||= asset_cache[param['target_asset_id']]
      param
    end
    super(optimized_parameters)
  end

  # Args is an array of transfer request parameters (in hash format)
  # We extract any referenced asset and target asset ids into an array.
  def extract_asset_ids(args)
    args.each_with_object([]) do |param, asset_ids|
      asset_ids << param[:asset_id] if param[:asset_id]
      asset_ids << param[:target_asset_id] if param[:target_asset_id]
    end
  end
end
