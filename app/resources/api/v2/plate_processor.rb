module Api
  module V2
    # This class defines the callback for the creation of the resource that we use
    # for creating the model using Heron::Factories::Plate.
    # If the factory detects any problem it returns a 422 with the error messages.
    # Otherwise it will be a 201
    class PlateProcessor < JSONAPI::Processor
      def create_resource
        factory = ::Heron::Factories::Plate.new(params_for_creation)
        build_resource_response(factory) || super
      end

      def build_resource_response(factory)
        if factory.valid?
          plate = nil
          ActiveRecord::Base.transaction do
            plate = factory.create
          end
          JSONAPI::ResourceOperationResult.new(:created,
                                               PlateResource.new(plate, @context))
        else
          JSONAPI::ErrorsOperationResult.new(:unprocessable_entity, errors_for_factory(factory))
        end
      rescue StandardError => e
        error_objs = errors_for_factory(factory) || ErrorForOperation.new(:internal_server_error, e.msg)
        JSONAPI::ErrorsOperationResult.new(:internal_server_error, error_objs)
      end

      # JSON-API resources requires a model that responds to :status when generating the error
      # response using ErrorsOperationResult. This class encapsulates the ActiveModel::Errors
      # list so it can be rendered by ErrorsOperationResult
      class ErrorForOperation
        def initialize(status, msg)
          @status = status
          @msg = msg
        end

        attr_reader :status

        def to_s
          @msg
        end
      end

      # It generates a list of ErrorForOperation that can be used by JSONapi::ErrorsOperationResult
      # to render the error message from the Plate factory
      def errors_for_factory(factory)
        factory.errors.full_messages.map do |msg|
          ErrorForOperation.new(:unprocessable_entity, msg)
        end
      end

      # wells_content is not part of the standard set of attributes for plate so it needed to be
      # permitted
      def params_for_creation
        params.dig(:data, :attributes).tap do |attrs|
          attrs[:wells_content].permit!
        end
      end
    end
  end
end
