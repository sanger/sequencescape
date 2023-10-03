# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for TubeFromTubeCreations
class Endpoints::TubeFromTubeCreations < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:child, json: 'child', to: 'child')
    belongs_to(:child_purpose, json: 'child_purpose')
    belongs_to(:parent, json: 'parent')
    belongs_to(:user, json: 'user')
  end
end
