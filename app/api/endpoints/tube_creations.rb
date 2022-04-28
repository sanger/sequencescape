# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for TubeCreations
class Endpoints::TubeCreations < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    has_many(:children, json: 'children', to: 'children')
    belongs_to(:child_purpose, json: 'child_purpose')
    belongs_to(:parent, json: 'parent')
    belongs_to(:user, json: 'user')
  end
end
