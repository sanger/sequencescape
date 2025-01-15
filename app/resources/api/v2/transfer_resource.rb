# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/transfers/` endpoint.
    #
    # Provides a JSON:API representation of {Transfer}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] destination_uuid
      #   @deprecated Use the `destination` relationship instead.
      #   Setting this attribute alongside the `destination` relationship will prefer the relationship value.
      #   @return [String, Void] the UUID of the destination labware.
      #   @see #destination
      attribute :destination_uuid

      def destination_uuid
        @model.destination&.uuid
      end

      def destination_uuid=(uuid)
        @model.destination = Labware.with_uuid(uuid).first if uuid
      end

      # @!attribute [rw] source_uuid
      #   @deprecated Use the `source` relationship instead.
      #   Setting this attribute alongside the `source` relationship will prefer the relationship value.
      #   @return [String] the UUID of the source labware.
      #     The type of the labware varies by the type of transfer.
      #   @see #source
      attribute :source_uuid

      def source_uuid
        @model.source.uuid
      end

      def source_uuid=(uuid)
        @model.source = Labware.with_uuid(uuid).first
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
      attribute :transfer_template_uuid, writeonly: true

      def transfer_template_uuid=(uuid)
        # Do not update the model.
        # This value is used by the controller to create the correct Transfer type and set the transfers attribute.
        # It is not stored on the Transfer model.
      end

      # @!attribute [r] transfer_type
      #   @return [String] The STI type of the transfer.
      attribute :transfer_type, delegate: :sti_type, readonly: true

      # @!attribute [rw] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @return [String] The UUID of the user who requested the transfer.
      #   @see #user
      attribute :user_uuid, write_once: true

      def user_uuid
        @model.user&.uuid # Some old data may not have a User relationship even though it's required for new records.
      end

      def user_uuid=(uuid)
        @model.user = User.with_uuid(uuid).first
      end

      # @!attribute [r] uuid
      #   @return [String] the UUID of the transfer.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] destination
      #   The destination Labware for the transfer.
      #   Setting this relationship alongside the `destination_uuid` attribute will override the attribute value.
      #   @return [LabwareResource, Void]
      has_one :destination

      # @!attribute [rw] source
      #   The source labware for the transfer. The type of the labware varies by the type of transfer.
      #   Setting this relationship alongside the `source_uuid` attribute will override the attribute value.
      #   @return [LabwareResource]
      #   @note This relationship is required.
      has_one :source, class_name: 'Labware'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who requested the transfer.
      #   @note This relationship is required.
      has_one :user

      ###
      # Filters
      ###

      # @!method transfer_type
      #   A filter to restrict the type of transfer to retrieve.
      #   One of the following types:
      #     - 'Transfer::BetweenPlateAndTubes'
      #     - 'Transfer::BetweenPlatesBySubmission'
      #     - 'Transfer::BetweenPlates'
      #     - 'Transfer::BetweenSpecificTubes'
      #     - 'Transfer::BetweenTubesBySubmission'
      #     - 'Transfer::FromPlateToSpecificTubesByPool'
      #     - 'Transfer::FromPlateToSpecificTubes'
      #     - 'Transfer::FromPlateToTubeByMultiplex'
      #     - 'Transfer::FromPlateToTubeBySubmission'
      #     - 'Transfer::FromPlateToTube'
      filter :transfer_type, apply: ->(records, value, _options) { records.where(sti_type: value) }

      ###
      # Create method
      ###

      # @!method create_with_model
      #   Create a new Transfer resource with the polymorphic type extracted from a template. This is called by the
      #   controller when a create request for a Transfer is made.
      # @param context [Hash] The context for the request.
      # @param model_type [Class] The polymorphic type of the Transfer model to create.
      # @return [TransferResource] The new Transfer resource.
      def self.create_with_model(context, model_type)
        # Create the polymorphic type, not the base class.
        new(model_type.new, context)
      end
    end
  end
end
