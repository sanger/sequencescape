# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/requests/` endpoint.
    #
    # Provides a JSON:API representation of {Request}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class RequestResource < BaseResource
      # Constants...

      # model_name / model_hint if required

      default_includes :uuid_object,
                       { request_metadata: %i[bait_library primer_panel] },
                       :pooled_request,
                       :order_role,
                       :submission

      # Associations:
      has_one :submission, always_include_linkage_data: true
      has_one :order, always_include_linkage_data: true
      has_one :request_type, always_include_linkage_data: true
      has_one :primer_panel
      has_one :pre_capture_pool
      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'
      has_one :request_metadata, class_name: 'RequestMetadata', foreign_key_on: :related

      # Attributes
      attribute :uuid, readonly: true
      attribute :role, readonly: true
      attribute :state
      attribute :priority, readonly: true
      attribute :options
      attribute :library_type, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # rubocop:todo Metrics/MethodLength
      def options # rubocop:todo Metrics/AbcSize
        # We need to pass in the attribute details here, as eager loading the metadata just instantiates
        # Request::Metadata
        # TODO: Nuke the separate metadata classes and metaprogramming
        {}.tap do |attrs|
          metadata_class = _model.class::Metadata
          _model
            .request_metadata
            .attribute_value_pairs(metadata_class.attribute_details)
            .each { |attribute, value| attrs[attribute.name.to_s] = value unless value.nil? }
          _model
            .request_metadata
            .association_value_pairs(metadata_class.association_details)
            .each { |association, value| attrs[association.name.to_s] = value unless value.nil? }
        end
      end

      # rubocop:enable Metrics/MethodLength

      # JSONAPI::Resource doesn't support has_one through relationships by default
      def primer_panel_id
        _model.request_metadata.primer_panel_id
      end

      def pre_capture_pool_id
        _model.pooled_request&.pre_capture_pool_id
      end

      def library_type
        _model.try(:library_type)
      end

      # Class method overrides
    end
  end
end
