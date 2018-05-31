
class ::Endpoints::LibraryTubes < ::Endpoints::Tubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    belongs_to(:purpose, json: 'purpose')
    has_many(:requests,         json: 'requests', to: 'requests')
    belongs_to(:source_request, json: 'source_request')
  end
end
