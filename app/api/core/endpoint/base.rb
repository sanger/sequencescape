# frozen_string_literal: true

# @abstract Define new endpoints by specifying {#model} and {#instance} actions
#
# Core class for {file:docs/api_v1.md API V1} endpoints, which effectively acts as a controller layer.
# New endpoints should be placed in `app/api/endpoints/` and should inherit from Core::Endpoint::Base.
# All endpoints are in the {Endpoints} namespace.
#
# @example Asset Audit
#   class ::Endpoints::AssetAudits < ::Core::Endpoint::Base
#    model do
#      action(:create) do |request, _response|
#        request.create!
#      end
#    end
#
#    instance do
#      belongs_to(:asset, json: 'asset')
#    end
#   end
#
# {#model model} defines actions on the collection, in the asset audit example a
# create action on `api/1/asset_audits`
#
# {#instance instance} defines actions on individual instances, usually accessed via
# their uuid. In this case each asset audit has an asset action which returns the associated asset.
# ie. `api/1/000000-0000-0000-0000-000000000000/asset`
#
# There is no need to modify the routes when adding endpoints.
#
# It is not necessary to define index or show endpoints, these are defined by default.
#
# @see Core::Endpoint::Base::InstanceBehaviour
# @see Core::Endpoint::Base::ModelBehaviour
# @see Core::Endpoint::BasicHandler
class Core::Endpoint::Base
  # Adds ability to define instance endpoints to Core::Endpoint::Base
  module InstanceBehaviour
    # @abstract Sub-classed automatically for each instance endpoint, and effectively acts as a controller.
    class Handler < Core::Endpoint::BasicHandler
      standard_action(:read)

      private

      def _read(request, _)
        yield(self, request.target)
      end
    end

    def self.extended(base)
      base.class_attribute :instance_handler, instance_writer: false
    end

    #
    # Opens up a block for defining endpoints on an instance of the model
    # @yield [] Yields control to block evaluated by the InstanceBehaviour::Handler
    #           This is where you define your actions.
    #
    # @return [Void]
    def instance(&block)
      handler = Class.new(Handler).tap { |handler_class| const_set(:Instance, handler_class) }.new(&block)
      handler.instance_variable_set(:@name, name)
      self.instance_handler = handler
    end
  end

  # Adds ability to define collection endpoints to Core::Endpoint::Base
  module ModelBehaviour
    # @abstract Sub-classed automatically for each model endpoint, and effectively acts as a controller.
    class Handler < Core::Endpoint::BasicHandler
      include Core::Endpoint::BasicHandler::Paged
      standard_action(:read)

      private

      def _read(request, _)
        request.target.order(:id).scoping do
          page    = request.path.first.try(:to_i) || 1
          results = page_of_results(request.io.eager_loading_for(request.target).include_uuid, page, request.target)
          results.singleton_class.send(:define_method, :model) { request.target }
          yield(self, results)
        end
      end
    end

    def self.extended(base)
      base.class_attribute :model_handler, instance_writer: false
    end

    #
    # Opens up a block for defining endpoints on the collection for a given model
    # @yield [] Yields control to block evaluated by the ModelBehaviour::Handler
    #           This is where you define your actions.
    #
    # @return [Void]
    def model(&block)
      handler = Class.new(Handler).tap { |handler_class| const_set(:Model, handler_class) }.new(&block)
      self.model_handler = handler
    end
  end

  extend InstanceBehaviour
  extend ModelBehaviour

  def self.root
    name.sub(/^(::)?Endpoints::/, '').underscore.pluralize
  end
end
