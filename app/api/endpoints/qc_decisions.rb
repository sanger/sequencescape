# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for QcDecisions
class Endpoints::QcDecisions < Core::Endpoint::Base
  model do
    action(:create) do |request, _|
      request.target.create!(
        request.attributes.tap do |attributes|
          attributes[:decisions] =
            (attributes[:decisions] || []).map do |d|
              d.merge('qcable' => Uuid.find_by(external_id: d['qcable']).resource)
            end
        end
      )
    end
  end

  instance do
    belongs_to(:user, json: 'user')
    belongs_to(:lot, json: 'lot')
    has_many(:qcables, json: 'qcables', to: 'qcables')
  end
end
