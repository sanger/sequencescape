# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for LibraryTubes
class Endpoints::LibraryTubes < ::Endpoints::Tubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    belongs_to(:purpose, json: 'purpose')
    has_many(:requests_as_source, json: 'requests', to: 'requests')
    belongs_to(:source_request, json: 'source_request')
  end
end
