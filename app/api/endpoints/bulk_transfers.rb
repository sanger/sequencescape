# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for BulkTransfers
class Endpoints::BulkTransfers < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:user, json: 'user')
    has_many(:transfers, json: 'transfers', to: 'transfers')
  end
end
