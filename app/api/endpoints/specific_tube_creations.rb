# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for SpecificTubeCreations
class Endpoints::SpecificTubeCreations < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    has_many(:children, json: 'children', to: 'children')
    has_many(:child_purposes, json: 'child_purposes', to: 'child_purposes')
    has_many(:parents, json: 'parents', to: 'parents')
    belongs_to(:user, json: 'user')
  end
end
