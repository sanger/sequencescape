# frozen_string_literal: true

require_dependency 'app/resources/api/v2/receptacle_resource'

module Api
  module V2
    #
    # Class WorkOrderResource provides an abstraction of
    # request for exposure to external applications. It
    # is intended to allow us to update the internal
    # representation, while maintaining an external
    # interface
    #
    class WorkOrderResource < BaseResource
      IGNORED_METADATA_FIELDS = %w[id request_id created_at updated_at].freeze

      default_includes [{ example_request: :request_metadata }, :work_order_type]

      has_one :study, readonly: true
      has_one :project, readonly: true
      has_one :source_receptacle, readonly: true, class_name: 'Receptacle'
      has_many :samples, readonly: true

      attribute :order_type, readonly: true
      attribute :quantity, readonly: true
      attribute :state
      attribute :options
      attribute :at_risk

      filter :state
      filter :order_type,
             apply:
               (
                 lambda do |records, value, _options|
                   records.joins(:work_order_type).where(work_order_types: { name: value })
                 end
               )

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
