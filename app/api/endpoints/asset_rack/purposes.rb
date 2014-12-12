class ::Endpoints::AssetRack::Purposes < ::Core::Endpoint::Base
  model do

  end

  instance do
    # has_many(:child_purposes, :json => 'children', :to => 'children')

    # has_many(:asset_racks, :json => 'asset_racks', :to => 'asset_racks') do
    #   action(:create) do |request, _|
    #     ActiveRecord::Base.transaction do
    #       request.target.proxy_owner.create!(request.attributes)
    #     end
    #   end
    # end
  end
end
