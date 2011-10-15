class ::Endpoints::Requests < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:asset,        :json => 'source_asset')
    belongs_to(:target_asset, :json => 'target_asset')
    belongs_to(:submission,   :json => 'submission')
  end
end
