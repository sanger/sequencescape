# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of TagLayoutTemplate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagLayoutTemplateResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :tag_group
      has_one :tag2_group

      # Attributes
      attribute :uuid, readonly: true
      attribute :direction, readonly: true
      attribute :walking_by, readonly: true

      # Filters
      filter :enabled, default: true

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
