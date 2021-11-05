# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for PooledPlateCreations
class Endpoints::PooledPlateCreations < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:child, json: 'child')
    belongs_to(:child_purpose, json: 'child_purpose')
    has_many(:parents, json: 'parents', to: 'parents')
    belongs_to(:user, json: 'user')
  end
end
