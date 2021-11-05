# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Requests
class Endpoints::Requests < ::Core::Endpoint::Base
  model {}

  instance do
    belongs_to(:asset, json: 'source_asset')
    belongs_to(:target_asset, json: 'target_asset')
    belongs_to(:submission, json: 'submission')
  end
end
