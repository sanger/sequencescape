# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for StateChanges
class Endpoints::StateChanges < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:target, json: 'target')
    belongs_to(:user, json: 'user')
  end
end
