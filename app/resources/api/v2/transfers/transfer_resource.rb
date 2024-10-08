# frozen_string_literal: true

module Api
  module V2
    module Transfers
      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note Access this resource via the `/api/v2/transfers/transfers/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class TransferResource < BaseResource
        # @!attribute [r] uuid
        #   @return [String] the UUID of the transfer.
        attribute :uuid

        # @!attribute [rw] source_uuid
        #   @return [String] the UUID of the source labware.
        #     The type of the labware varies by the type of transfer.
        attribute :source_uuid

        def source_uuid
          @model.source.uuid
        end

        def source_uuid=(uuid)
          @model.source = Labware.with_uuid(uuid).first
        end

        # @!attribute [rw] destination_uuid
        #   @return [String, void] the UUID of the destination labware.
        attribute :destination_uuid

        def destination_uuid
          @model.destination&.uuid
        end

        def destination_uuid=(uuid)
          @model.destination = Labware.with_uuid(uuid).first if uuid
        end

        # @!attribute [rw] user_uuid
        #   @return [String] the UUID of the user who requested the transfer.
        attribute :user_uuid

        def user_uuid
          @model.user&.uuid # Some old data may not have a User relationship even though it's required for new records.
        end

        def user_uuid=(uuid)
          @model.user = User.with_uuid(uuid).first
        end

        # @!attribute [rw] transfers
        #   @return [Hash] a hash of the transfers made.
        #     This is usually populated by the TransferTemplate used during creation of the Transfer.
        attribute :transfers

        def transfers
          # Only some transfer types have the :transfers method.
          # This gets implemented differently, depending on the type of transfer being performed.
          return nil unless @model.respond_to?(:transfers)

          @model.transfers
        end

        def transfers=(transfers)
          # This setter is invoked by the TransferTemplate populating the attributes for transfers.
          @model.transfers =
            if transfers.is_a?(ActionController::Parameters)
              transfers.to_unsafe_h # We must unwrap the parameters to a real Hash.
            else
              transfers
            end
        end

        # @!attribute [w] transfer_template_uuid
        #   @return [String] the UUID of a TransferTemplate to create a transfer from.
        #     This must be provided or the Transfer creation will raise an error.
        attribute :transfer_template_uuid

        def fetchable_fields
          # Do not fetch the transfer template.
          # It is only submitted when creating a new transfer and not stored.
          super - %i[transfer_template_uuid]
        end

        def self.creatable_fields(context)
          # Do not allow the UUID to be declared by the client.
          super - %i[uuid]
        end

        def self.create(context)
          # Create the polymorphic type, not the base class.
          new(context[:polymorphic_type].constantize.new, context)
        end
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/between_plate_and_tubes/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::BetweenPlateAndTubes}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class BetweenPlateAndTubeResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::BetweenPlateAndTubes'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/between_plates_by_submissions/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::BetweenPlatesBySubmission}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class BetweenPlatesBySubmissionResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::BetweenPlatesBySubmission'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/between_plates/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::BetweenPlates}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class BetweenPlateResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::BetweenPlates'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/between_specific_tubes/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::BetweenSpecificTubes}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class BetweenSpecificTubeResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::BetweenSpecificTubes'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/between_tubes_by_submissions/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::BetweenTubesBySubmission}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class BetweenTubesBySubmissionResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::BetweenTubesBySubmission'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/from_plate_to_specific_tubes_by_pools/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::FromPlateToSpecificTubesByPool}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class FromPlateToSpecificTubesByPoolResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::FromPlateToSpecificTubesByPool'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/from_plate_to_specific_tubes/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::FromPlateToSpecificTubes}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class FromPlateToSpecificTubeResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::FromPlateToSpecificTubes'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/from_plate_to_tube_by_multiplexes/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::FromPlateToTubeByMultiplex}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class FromPlateToTubeByMultiplexResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::FromPlateToTubeByMultiplex'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/from_plate_to_tube_by_submissions/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::FromPlateToTubeBySubmission}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class FromPlateToTubeBySubmissionResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::FromPlateToTubeBySubmission'
      end

      # @todo This documentation does not yet include a detailed description of what this resource represents.
      # @todo This documentation does not yet include any example usage of the API via cURL or similar.
      #
      # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
      # @note Access this resource via the `/api/v2/transfers/from_plate_to_tubes/` endpoint.
      #
      # Provides a JSON:API representation of {Transfer::FromPlateToTube}.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class FromPlateToTubeResource < TransferResource
        immutable
        filter :sti_type, default: 'Transfer::FromPlateToTube'
      end
    end
  end
end
