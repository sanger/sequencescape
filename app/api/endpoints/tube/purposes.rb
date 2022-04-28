# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Tube
class Endpoints::Tube::Purposes < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    has_many(:child_purposes, json: 'children', to: 'children')
    has_many(:parent_purposes, json: 'parents', to: 'parents')
    has_many(:tubes, json: 'tubes', to: 'tubes')
  end
end
