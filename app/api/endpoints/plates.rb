# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Plates
class Endpoints::Plates < Core::Endpoint::Base
  model {}

  instance do
    has_many(:comments, json: 'comments', to: 'comments') { action(:create, to: :standard_create!) }

    has_many(:volume_updates, json: 'volume_updates', to: 'volume_updates') { action(:create, to: :standard_create!) }

    has_many(:extraction_attributes, json: 'extraction_attributes', to: 'extraction_attributes') do
      action(:create, to: :standard_create!)
    end

    has_many(:wells, json: 'wells', to: 'wells', scoped: 'for_api_plate_json.in_row_major_order', per_page: 400)
    has_many(:submission_pools, json: 'submission_pools', to: 'submission_pools')
    belongs_to(:plate_purpose, json: 'plate_purpose')

    has_many(:qc_files, json: 'qc_files', to: 'qc_files', include: []) do
      action(:create, as: 'create') do |request, _|
        ActiveRecord::Base.transaction { QcFile.create!(request.attributes.merge(asset: request.target)) }
      end
      action(:create_from_file, as: 'create') do |request, _|
        ActiveRecord::Base.transaction { request.target.add_qc_file(request.file, request.filename) }
      end
    end

    has_many(:transfer_request_collections, json: 'transfer_request_collections', to: 'transfer_request_collections')

    has_many(:transfers_as_source, json: 'source_transfers', to: 'source_transfers')
    has_many(:transfers_to_tubes, json: 'transfers_to_tubes', to: 'transfers_to_tubes')
    has_many(:transfers_as_destination, json: 'creation_transfers', to: 'creation_transfers')
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
  end
end
