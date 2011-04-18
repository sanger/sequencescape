class ::Endpoints::AssetGroups < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:study, :json => "study")
    belongs_to(:submission, :json => "submission")
    has_many(:assets, :include => [], :json => "assets", :to => "assets")
  end
end
