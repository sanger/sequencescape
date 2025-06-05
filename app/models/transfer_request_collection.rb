# frozen_string_literal: true

# A transfer request collection provides a means
# of bulk creating transfer requests between arbitrary
# sources and destinations.
# Used to provide a means of bulk creating transfer requests via the API
class TransferRequestCollection < ApplicationRecord
  include Uuid::Uuidable

  # Extracts all the uuids from the query and caches the associated information
  # Greatly improves performance.
  class UuidCache
    def initialize(parameters)
      uuids = parameters.flat_map(&:values).select { |v| v.is_a?(String) && Uuid::VALID_REGEXP.match?(v) }
      @cache =
        Uuid
          .where(external_id: uuids)
          .pluck(:external_id, :resource_type, :resource_id)
          .each_with_object({}) { |uuid_item, store| store[uuid_item[0, 2]] = uuid_item[-1] }
      extract_receptacles_from_labware
    end

    def find(klass, uuid)
      @cache[[uuid, klass.base_class.name]]
    end

    private

    # To maintain API compatibility we allow for labware to be supplied, this allows
    # a receptacle to be looked up via its labware with just one additional query for transfer collection
    def extract_receptacles_from_labware
      labware_entries = @cache.select { |uuid_class, _| uuid_class.last == 'Labware' }
      labware_receptacles = Receptacle.where(labware_id: labware_entries.values).pluck(:labware_id, :id).to_h
      labware_entries.each do |uuid_klass, labware_id|
        @cache[[uuid_klass.first, 'Receptacle']] = labware_receptacles[labware_id]
      end
    end
  end

  has_many :transfer_request_collection_transfer_requests, dependent: :destroy
  has_many :transfer_requests,
           through: :transfer_request_collection_transfer_requests,
           inverse_of: :transfer_request_collections

  # Transfer requests themselves can go to any receptacle,
  # mostly wells and tubes. Unfortunately the current API
  # provides no effective means of handling this polymorphic
  # association elegantly, as the json root is not included in
  # a nested has_many association. This makes the handling of
  # class specific attributes, such as barcodes, a bit cumbersome,
  # especially when we are trying to eager load that information.
  has_many :target_tubes, -> { distinct }, through: :transfer_requests, source: :target_labware, class_name: 'Tube'

  belongs_to :user, optional: false
  accepts_nested_attributes_for :transfer_requests

  # The api is terrible at handling nested has_many relationships
  # This caches all our UUIDs in one query, and extracts the ids
  # rubocop:todo Metrics/MethodLength
  def transfer_requests_io=(parameters) # rubocop:todo Metrics/AbcSize
    uuid_cache = UuidCache.new(parameters)

    updated_attributes =
      parameters.map do |parameter|
        if parameter['source_asset'].is_a?(String)
          parameter['asset_id'] = uuid_cache.find(Receptacle, parameter.delete('source_asset'))
        end
        parameter['asset'] = parameter.delete('source_asset') if parameter['source_asset'].present?
        if parameter['target_asset'].is_a?(String)
          parameter['target_asset_id'] = uuid_cache.find(Receptacle, parameter.delete('target_asset'))
        end
        if parameter['submission'].is_a?(String)
          parameter['submission_id'] = uuid_cache.find(Submission, parameter.delete('submission'))
        end
        if parameter['outer_request'].is_a?(String)
          parameter['outer_request_id'] = uuid_cache.find(Request, parameter.delete('outer_request'))
        end
        parameter
      end

    self.transfer_requests_attributes = updated_attributes
  end

  # rubocop:enable Metrics/MethodLength

  # These are optimizations to reduce the number of queries that need to be
  # performed while the transfer takes place.
  # Transfer requests rely both on the aliquots in an assets, and the transfer requests
  # into the asset (used to track state). Here we eager load all necessary assets
  # and associated records, and pass them to the transfer requests directly.
  def transfer_requests_attributes=(args) # rubocop:todo Metrics/MethodLength
    asset_ids = extract_asset_ids(args)
    asset_cache =
      Receptacle
        .includes(:aliquots, :transfer_requests_as_target, requests: :request_metadata, labware: :purpose)
        .find(asset_ids)
        .index_by(&:id)
    optimized_parameters =
      args.map do |param|
        param['asset'] ||= asset_cache[param.delete('asset_id')]
        param['target_asset'] ||= asset_cache[param.delete('target_asset_id')]
        param
      end
    super(optimized_parameters)
  end

  # Args is an array of transfer request parameters (in hash format)
  # We extract any referenced asset and target asset ids into an array.
  def extract_asset_ids(args)
    args.each_with_object([]) do |param, asset_ids|
      param.stringify_keys!
      asset_ids << param['asset_id'] if param['asset_id']
      asset_ids << param['target_asset_id'] if param['target_asset_id']
    end
  end
end
