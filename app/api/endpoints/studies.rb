class Endpoints::Studies < Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:samples,      :json => 'samples',      :to => 'samples')
    has_many(:projects,     :json => 'projects',     :to => 'projects')
    has_many(:asset_groups, :json => 'asset_groups', :to => 'asset_groups')
  end
end

