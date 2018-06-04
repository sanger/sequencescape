
class ::Endpoints::SampleTubes < ::Endpoints::Tubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    has_many(:requests,      json: 'requests',      to: 'requests')
    has_many(:library_tubes, json: 'library_tubes', to: 'library_tubes')
  end
end
