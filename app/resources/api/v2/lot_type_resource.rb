# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/lot_types/` endpoint.
    #
    # Provides a JSON:API representation of {LotType}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LotTypeResource < BaseResource
      # Constants...

      immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :target_purpose, write_once: true, class_name: 'Purpose'

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, write_once: true
      attribute :template_type, write_once: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Our internal class names don't make much sense via the API, so we expose
      # the corresponding resource type instead.
      def template_type
        template_type = _model.template_class.underscore
        self.class._model_hints[template_type] || template_type
      end

      # Class method overrides
    end
  end
end
