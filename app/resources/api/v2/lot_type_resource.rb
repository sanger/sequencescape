# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of LotType
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class LotTypeResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :target_purpose, readonly: true, class_name: 'Purpose'

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :template_type, readonly: true

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
