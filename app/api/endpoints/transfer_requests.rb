# frozen_string_literal: true

# TransferRequests are exposed via the API and allow
# you to access their source and target assets, and their submissions
class ::Endpoints::TransferRequests < ::Core::Endpoint::Base
  model do
  end

  instance do
    belongs_to(:asset,        json: 'source_asset')
    belongs_to(:target_asset, json: 'target_asset')
    belongs_to(:submission,   json: 'submission')
  end
end
