# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of request
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class RequestResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :submission, always_include_linkage_data: true
      has_one :order, always_include_linkage_data: true
      has_one :request_type, always_include_linkage_data: true
      has_one :primer_panel

      # Attributes
      attribute :uuid, readonly: true
      attribute :role, readonly: true
      attribute :state, readonly: true
      attribute :priority, readonly: true
      attribute :options

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def options
        {}.tap do |attrs|
          _model.request_metadata.attribute_value_pairs.each do |attribute, value|
            attrs[attribute.name.to_s] = value unless value.nil?
          end
          _model.request_metadata.association_value_pairs.each do |association, value|
            attrs[association.name.to_s] = value unless value.nil?
          end
        end
      end

      # JSONAPI::Resource doesn't support has_one through relationships by default
      def primer_panel_id
        _model.request_metadata.primer_panel_id
      end

      # Class method overrides
    end
  end
end
