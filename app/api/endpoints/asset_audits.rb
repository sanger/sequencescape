class ::Endpoints::AssetAudits < ::Core::Endpoint::Base
  model do

    action(:create) do |request, response|
      request.create!
    end
  end

  instance do
    belongs_to(:asset, :json => "asset")

  end
end
