# frozen_string_literal: true

module Api
  module V2
    module Transfers
      # Provides a JSON API controller for Transfers.
      # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
      class TransfersController < JSONAPI::ResourceController
        # By default JSONAPI::ResourceController provides most of the standard behaviour.
        # However in this case we want to redirect create and update operations to the correct polymorphic type.

        def process_operations(operations)
          # We need to determine the polymorphic type of the transfer to create based on any template provided.
          operations.each do |operation|
            context = operation.options[:context]
            attributes = operation.options[:data][:attributes]

            # Only add a polymorphic type if we have a transfer template.
            if attributes.key?(:transfer_template_uuid)
              template = TransferTemplate.with_uuid(attributes[:transfer_template_uuid]).first
              context[:polymorphic_type] = template.transfer_class_name
            end

            # Remove the UUID of the transfer template from the attributes.
            attributes.delete(:transfer_template_uuid)
          end

          super(operations)
        end
      end

      class BetweenPlateAndTubesController < JSONAPI::ResourceController
      end

      class BetweenPlatesBySubmissionsController < JSONAPI::ResourceController
      end

      class BetweenPlatesController < JSONAPI::ResourceController
      end

      class BetweenSpecificTubesController < JSONAPI::ResourceController
      end

      class BetweenTubesBySubmissionsController < JSONAPI::ResourceController
      end

      class FromPlateToSpecificTubesByPoolsController < JSONAPI::ResourceController
      end

      class FromPlateToSpecificTubesController < JSONAPI::ResourceController
      end

      class FromPlateToTubeByMultiplexesController < JSONAPI::ResourceController
      end

      class FromPlateToTubeBySubmissionsController < JSONAPI::ResourceController
      end

      class FromPlateToTubesController < JSONAPI::ResourceController
      end
    end
  end
end
