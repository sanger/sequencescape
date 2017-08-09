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
      IGNORED_METADATA_FIELDS = %w(id request_id created_at updated_at).freeze

      default_includes [:example_request, :work_order_type, { requests: :request_metadata }]

      has_one :study, readonly: true # , foreign_key: :initial_study_id#, relation_name: :initial_study
      has_one :project, readonly: true # , foreign_key: :initial_project_id#, relation_name: :initial_project
      has_one :source_receptacle, readonly: true, polymorphic: true # foreign_key: :asset_id, relation_name: :asset, polymorphic: true
      has_many :samples, readonly: true

      attribute :order_type, readonly: true
      attribute :quantity, readonly: true
      attribute :state
      attribute :options
      attribute :at_risk

      filter :state, apply: (lambda do |records, value, _options|
        records.where(requests: { state: value })
      end)

      filter :order_type, apply: (lambda do |records, value, _options|
        records.where(work_order_types: { name: value })
      end)

      def quantity
        {
          value: _model.quantity_value,
          unit: _model.quantity_units
        }
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
        _model.requests.first.request_metadata.attributes.reject do |key, value|
          IGNORED_METADATA_FIELDS.include?(key) || value.blank?
        end
      end
    end
  end
end
