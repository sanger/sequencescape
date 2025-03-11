# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {WorkOrder} for managing work orders within the application.
    #
    # A Work order groups requests together based on Submission and Asset
    # providing a unified interface for external applications.
    #
    # This resource can be accessed via the `/api/v2/work_orders/` endpoint.
    #
    # @note the below example is currently broken, as `work_order_type` is a required attribute in the model
    # @example POST request to create a new {WorkOrder}
    #   POST /api/v2/work_orders/
    # {
    #   "data": {
    #     "type": "work_orders",
    #     "attributes": {
    #       "state": "pending",
    #       "work_order_type": "standard"
    #       // "order_type": "standard"
    #     },
    #     "relationships": {
    #     }
    #   }
    # }
    #
    # @example GET request to retrieve all work orders
    #   GET /api/v2/work_orders/
    #
    # @example GET request to retrieve a specific work order with ID 123
    #   GET /api/v2/work_orders/123/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class WorkOrderResource < BaseResource
      IGNORED_METADATA_FIELDS = %w[id request_id created_at updated_at].freeze

      ###
      # Attributes
      ###

      # @!attribute [rw] at_risk
      #   Indicates whether the customer accepts responsibility
      #   @return [Boolean] `true` if customer accepts responsibility, `false` otherwise.
      #   @note This attribute is optional.
      attribute :at_risk

      # @!attribute [r] options
      #   A set of request metadata options associated with the work order.
      #   This field is read-only and cannot be modified directly.
      #   @return [Hash] Metadata options, excluding ignored fields.
      #   @note This attribute is read-only.
      attribute :options, readonly: true

      # @!attribute [rw] order_type
      #   Specifies the type of the work order.
      #   Initally, the order type reflects the request type of the provided request.
      #   This attribute is write-once and cannot be changed after creation.
      #   @return [String] The type of work order.
      #   @note This attribute is required during creation and cannot be modified after creation.
      attribute :order_type, write_once: true

      # @!attribute [rw] quantity
      #   Specifies the quantity of work orders to be processed.
      #   This attribute is write-once and cannot be changed after creation.
      #   @return [Integer] The quantity of work orders.
      #   @note This attribute is required during creation and cannot be modified after creation.
      attribute :quantity, write_once: true

      # @!attribute [rw] state
      #   Represents the current state of the work order.
      #   @return [String] The state of the work order.
      #   @note This attribute is required.
      attribute :state

      ###
      # Relationships
      ###

      # @!attribute [rw] study
      #   The study associated with the work order.
      #   @return [StudyResource] The related study resource.
      #   @note This relationship is write-once and cannot be modified after creation.
      has_one :study, write_once: true

      # @!attribute [rw] project
      #   The project associated with the work order.
      #   @return [ProjectResource] The related project resource.
      #   @note This relationship is write-once and cannot be modified after creation.
      has_one :project, write_once: true

      # @!attribute [rw] source_receptacle
      #   The source receptacle from which the work order originates.
      #   @return [PolymorphicResource] The source receptacle related to the work order.
      #   @note This relationship is write-once and cannot be modified after creation.
      has_one :source_receptacle, write_once: true, polymorphic: true

      # @!attribute [rw] samples
      #   The samples related to the work order.
      #   @return [Array<SampleResource>] An array of sample resources.
      #   @note This relationship is write-once and cannot be modified after creation.
      has_many :samples, write_once: true

      ###
      # Filters
      ###

      # @!method :order_type
      #   Filters work orders by their type.
      #   @example Use this filter to find work orders of type "standard":
      #     GET /api/v2/work_orders?filter[order_type]=standard
      filter :order_type,
             apply:
               (
                 lambda do |records, value, _options|
                   records.joins(:work_order_type).where(work_order_types: { name: value })
                 end
               )

      # @!method :state
      #   Filters work orders by their state.
      #   @example Use this filter to find work orders in "open" state:
      #     GET /api/v2/work_orders?filter[state]=open
      filter :state

      ###
      # Getter Methods
      ###

      # @!method quantity
      #   Returns the quantity of work orders along with the unit of measurement.
      #   @return [Hash] A hash containing the quantity and unit of measurement.
      #   @example { number: 5, unit_of_measurement: "units" }
      def quantity
        { number: _model.quantity_value, unit_of_measurement: _model.quantity_units }
      end

      # @!method study_id
      #   Returns the study ID associated with the work order via an example request.
      #   @return [String] The associated study ID.
      def study_id
        _model.example_request.initial_study_id
      end

      # @!method project_id
      #   Returns the project ID associated with the work order via an example request.
      #   @return [String] The associated project ID.
      def project_id
        _model.example_request.initial_project_id
      end

      # @!method source_receptacle_id
      #   Returns the source receptacle ID associated with the work order via an example request.
      #   @return [String] The associated source receptacle ID.
      def source_receptacle_id
        _model.example_request.asset_id
      end

      # @!method order_type
      #   Returns the name of the work order type.
      #   @return [String] The name of the work order type (e.g., "standard").
      def order_type
        _model.work_order_type.name
      end

      # @!method options
      #   Returns the filtered metadata options associated with the work order.
      #   @return [Hash] A hash of metadata options, excluding ignored fields.
      def options
        _model.example_request.request_metadata.attributes.reject do |key, value|
          IGNORED_METADATA_FIELDS.include?(key) || value.blank?
        end
      end
    end
  end
end
