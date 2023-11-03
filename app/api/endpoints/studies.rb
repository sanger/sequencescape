# frozen_string_literal: true
class Endpoints::Studies < Core::Endpoint::Base
  model {}

  instance do
    has_many(:samples, json: 'samples', to: 'samples')
    has_many(:projects, json: 'projects', to: 'projects')
    has_many(:asset_groups, json: 'asset_groups', to: 'asset_groups')

    has_many(:sample_manifests, json: 'sample_manifests', to: 'sample_manifests') do
      def self.deprecated_constructor(name)
        line = __LINE__ + 1
        instance_eval(
          "
          bind_action(:create, :as => #{name.to_sym.inspect}, :to => #{name.to_s.inspect}) do |_, request, response|
            raise ::Core::Service::DeprecatedAction
          end
        ",
          __FILE__,
          line
        )
      end

      deprecated_constructor(:create_for_plates)
      deprecated_constructor(:create_for_tubes)
      deprecated_constructor(:create_for_multiplexed_libraries)
      deprecate :create_for_plates, :create_for_tubes, :create_for_multiplexed_libraries
    end
  end
end
