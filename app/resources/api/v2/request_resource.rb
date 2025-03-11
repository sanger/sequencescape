# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Request}.
    #
    # A Request represents work which needs to be done, either to fulfil a customers
    # needs {CustomerRequest} or for internal reasons {SystemRequest}.
    # The progress of a request is tracked through its {Request::Statemachine state machine}.
    #
    # Access this resource via the `/api/v2/requests/` endpoint.
    #
    # @note This resource supports `GET` and `PATCH` requests. It allows fetching requests by their attributes
    #       and updating them.
    #
    # @example GET request to retrieve all requests
    #   GET /api/v2/requests/
    #
    # @example POST request to create a new request
    #   POST /api/v2/requests/
    # {
    #   "data": {
    #     "type": "requests",
    #     "attributes": {
    #       "role": "analysis",
    #       "state": "pending",
    #       "priority": "high"
    #     },
    #     "relationships": {
    #       "submission": {
    #         "data": {
    #           "type": "submissions",
    #           "id": "123"
    #         }
    #       },
    #       "order": {
    #         "data": {
    #           "type": "orders",
    #           "id": "456"
    #         }
    #       },
    #       "request_type": {
    #         "data": {
    #           "type": "request_types",
    #           "id": "789"
    #         }
    #       }
    #     }
    #   }
    # }
    #
    # @example PATCH request to update an existing request
    #   PATCH /api/v2/requests/1
    #   {
    #     "data": {
    #       "id": "1",
    #       "type": "requests",
    #       "attributes": {
    #         "state": "completed",
    #         "priority": "medium"
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class RequestResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The UUID of the request.
      #   @return [String] The unique identifier for the request.
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      attribute :uuid, readonly: true

      # @!attribute [rw] role
      #   The role of the request, such as "analysis" or "testing."
      #   @return [String] The role of the request.
      #   @note This attribute can only be set once.
      attribute :role, write_once: true

      # @!attribute [rw] state
      #   The current state of the request, such as "pending," "completed," or "in progress."
      #   @return [String] The state of the request.
      #   @note This field can be updated during the lifecycle of the request.
      attribute :state

      # @!attribute [rw] priority
      #   The priority of the request, such as "high," "medium," or "low."
      #   @return [String] The priority of the request.
      #   @note This attribute can only be set once.
      attribute :priority, write_once: true

      # @!attribute [r] options
      #   Additional options related to the request, such as configurations or metadata.
      #   @return [Hash] A hash containing additional options for the request.
      #   @note This attribute is read-only.
      attribute :options, readonly: true

      # @!attribute [r] library_type
      #   The type of library associated with the request, e.g., "scRNA" or "DNA."
      #   @return [String] The type of library associated with the request.
      #   @note This attribute is read-only.
      attribute :library_type, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] submission
      #   The submission associated with this request.

      has_one :submission, always_include_linkage_data: true

      # @!attribute [r] order
      #   The order associated with this request.

      has_one :order, always_include_linkage_data: true

      # @!attribute [r] request_type
      #   The type of the request, such as "analysis" or "testing."

      has_one :request_type, always_include_linkage_data: true

      # @!attribute [r] primer_panel
      #   The primer panel used for the request, if applicable.
      #   @return [PrimerPanelResource] The primer panel linked to the request.
      #   @note This relationship is read-only.
      has_one :primer_panel, readonly: true

      # @!attribute [r] pre_capture_pool
      #   The pre-capture pool associated with the request.
      #   @return [PreCapturePoolResource] The pre-capture pool linked to the request.
      #   @note This relationship is read-only.
      has_one :pre_capture_pool, readonly: true

      # @!attribute [r] poly_metadata
      #   The metadata associated with the request.
      #   @return [Array<PolyMetadatumResource>] The poly metadata linked to the request.
      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      # @!attribute [r] request_metadata
      #   The metadata associated with the request.
      #   @return [RequestMetadataResource] The request metadata linked to the request.
      has_one :request_metadata, class_name: 'RequestMetadata', foreign_key_on: :related

      ###
      # Field Methods
      ###

      # @note This method retrieves the options associated with the request, including metadata from the
      #       `request_metadata` relationship.
      def options # rubocop:todo Metrics/AbcSize
        # We need to pass in the attribute details here, as eager loading the metadata just instantiates
        # Request::Metadata
        # TODO: Nuke the separate metadata classes and metaprogramming
        {}.tap do |attrs|
          _model
            .request_metadata
            .attribute_value_pairs(_model.class::Metadata.attribute_details)
            .each { |attribute, value| attrs[attribute.name.to_s] = value unless value.nil? }
          _model
            .request_metadata
            .association_value_pairs(_model.class::Metadata.association_details)
            .each { |association, value| attrs[association.name.to_s] = value unless value.nil? }
        end
      end

      # JSONAPI::Resource doesn't support has_one through relationships by default
      # @note This method retrieves the primer panel ID associated with the request.
      def primer_panel_id
        _model.request_metadata.primer_panel_id
      end

      # @note This method retrieves the pre-capture pool ID associated with the request.
      def pre_capture_pool_id
        _model.pooled_request&.pre_capture_pool_id
      end

      # @note This method retrieves the library type associated with the request.
      def library_type
        _model.try(:library_type)
      end
    end
  end
end
