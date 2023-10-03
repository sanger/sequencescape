# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for PlateConversions
class Endpoints::PlateConversions < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:target, json: 'target')
    belongs_to(:purpose, json: 'purpose')
    belongs_to(:user, json: 'user')
    belongs_to(:parent, json: 'parent')
  end
end
