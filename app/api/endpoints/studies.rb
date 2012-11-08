class Endpoints::Studies < Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:samples,      :json => 'samples',      :to => 'samples')
    has_many(:projects,     :json => 'projects',     :to => 'projects')
    has_many(:asset_groups, :json => 'asset_groups', :to => 'asset_groups')

    has_many(:sample_manifests, :json => 'sample_manifests', :to => 'sample_manifests') do
      def self.constructor(name, method)
        line = __LINE__ + 1
        instance_eval(%Q{
          bind_action(:create, :as => #{name.to_sym.inspect}, :to => #{name.to_s.inspect}) do |_, request, response|
            ActiveRecord::Base.transaction do
              manifest = request.target.#{method}(request.attributes)
              request.io.eager_loading_for(manifest.class).include_uuid.find(manifest.id)
            end
          end
        }, __FILE__, line)
      end

      constructor(:create_for_plates, :create_for_plate!)
      constructor(:create_for_tubes, :create_for_sample_tube!)
    end
  end
end

