# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Stamps
class Endpoints::Stamps < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:user, json: 'user')
    belongs_to(:robot, json: 'robot')
    belongs_to(:lot, json: 'lot')
    has_many(:qcables, json: 'qcables', to: 'qcables')
    has_many(:stamp_qcables, json: 'stamp_qcables', to: 'stamp_qcables')
  end
end
