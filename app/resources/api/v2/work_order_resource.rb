# frozen_string_literal: true

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

      model_name 'CustomerRequest'

      CustomerRequest.descendants.each do |subclass|
        model_hint model: subclass, resource: :work_order
      end

      default_includes :uuid_object, :request_metadata, :request_type

      has_one :study, readonly: true, foreign_key: :initial_study_id, relation_name: :initial_study
      has_one :project, readonly: true, foreign_key: :initial_project_id, relation_name: :initial_project
      has_one :source_receptacle, readonly: true, foreign_key: :asset_id, relation_name: :asset, polymorphic: true
      has_many :samples, readonly: true

      attribute :uuid, readonly: true
      attribute :order_type, readonly: true
      attribute :state
      attribute :options, delegate: :request_metadata_attributes
      attribute :at_risk, delegate: :customer_accepts_responsibility

      filters :state

      filter :order_type, apply: ->(records, value, _options) {
        records.where(request_types: { key: value })
      }

      def order_type
        _model.request_type.key
      end

      def options
        _model.request_metadata.attributes.reject do |key, value|
          IGNORED_METADATA_FIELDS.include?(key) || value.blank?
        end
      end
    end
  end
end
