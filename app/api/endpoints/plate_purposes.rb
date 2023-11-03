# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for PlatePurposes
class Endpoints::PlatePurposes < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    has_many(:child_purposes, json: 'children', to: 'children')
    has_many(:parent_purposes, json: 'parents', to: 'parents')

    has_many(:plates, json: 'plates', to: 'plates') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction { request.target.proxy_association.owner.create!(request.attributes) }
      end
    end
  end
end
