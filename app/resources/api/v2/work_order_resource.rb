# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource (really) represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/work_orders/` endpoint.
    #
    # Provides a JSON:API representation of {WorkOrder}.
    # Work orders provide an abstraction of requests for exposure to external applications.
    # They are intended to allow us to update the internal representation, while maintaining an external interface.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.

    class WorkOrderResource < BaseResource
      IGNORED_METADATA_FIELDS = %w[id request_id created_at updated_at].freeze

      # Attributes
      attribute :at_risk
      attribute :options, readonly: true
      attribute :order_type, write_once: true
      attribute :quantity, write_once: true
      attribute :state

      # Relationships
      has_one :study, write_once: true
      has_one :project, write_once: true
      has_one :source_receptacle, write_once: true, polymorphic: true
      has_many :samples, write_once: true

      # Filters
      filter :order_type,
             apply:
               (
                 lambda do |records, value, _options|
                   records.joins(:work_order_type).where(work_order_types: { name: value })
                 end
               )
      filter :state

      # Field Methods
      def quantity
        { number: _model.quantity_value, unit_of_measurement: _model.quantity_units }
      end

      # JSONAPI::Resource doesn't support has_one through relationships by default
      def study_id
        _model.example_request.initial_study_id
      end

      # JSONAPI::Resource doesn't support has_one through relationships by default
      def project_id
        _model.example_request.initial_project_id
      end

      def source_receptacle_id
        _model.example_request.asset_id
      end

      def order_type
        _model.work_order_type.name
      end

      def options
        _model.example_request.request_metadata.attributes.reject do |key, value|
          IGNORED_METADATA_FIELDS.include?(key) || value.blank?
        end
      end
    end
  end
end
