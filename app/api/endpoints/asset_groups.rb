# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for AssetGroups
class Endpoints::AssetGroups < Core::Endpoint::Base
  model {}

  instance do
    belongs_to(:study, json: 'study')
    belongs_to(:submission, json: 'submission')
    has_many(:assets, include: [], json: 'assets', to: 'assets')
  end
end
