# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for SampleTubes
class Endpoints::SampleTubes < Endpoints::Tubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    has_many(:requests_as_source, json: 'requests', to: 'requests')
    has_many(:library_tubes, json: 'library_tubes', to: 'library_tubes')
  end
end
