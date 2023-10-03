# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Tubes
class Endpoints::Tubes < Core::Endpoint::Base
  model {}

  instance do
    has_many(:requests_as_source, json: 'requests', to: 'requests')
    belongs_to(:purpose, json: 'purpose')
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')

    has_many(:qc_files, json: 'qc_files', to: 'qc_files', include: []) do
      action(:create, as: 'create') do |request, _|
        ActiveRecord::Base.transaction { QcFile.create!(request.attributes.merge(asset: request.target)) }
      end
      action(:create_from_file, as: 'create') do |request, _|
        ActiveRecord::Base.transaction { request.target.add_qc_file(request.file, request.filename) }
      end
    end
  end
end
