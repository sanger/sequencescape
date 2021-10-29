# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for LotTypes
class Endpoints::LotTypes < ::Core::Endpoint::Base
  model {}

  instance do
    has_many(:lots, json: 'lots', to: 'lots') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction { request.target.proxy_association.owner.create!(request.attributes) }
      end
    end
  end
end
