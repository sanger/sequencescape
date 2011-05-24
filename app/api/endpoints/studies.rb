class Endpoints::Studies < Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:samples,      :json => 'samples',      :to => 'samples')
    has_many(:projects,     :json => 'projects',     :to => 'projects')
    has_many(:asset_groups, :json => 'asset_groups', :to => 'asset_groups')

    has_many(:sample_manifests, :json => 'sample_manifests', :to => 'sample_manifests') do
      bind_action(:create, :as => :create_for_plates, :to => 'create_for_plate') do |request, response|
        ActiveRecord::Base.transaction do
          request.target.create_for_plate!(request.attributes)
        end
      end
      bind_action(:create, :as => :create_for_tubes, :to => 'create_for_tubes') do |request, response|
        ActiveRecord::Base.transaction do
          request.target.create_for_sample_tube!(request.attributes)
        end
      end
    end
  end
end

