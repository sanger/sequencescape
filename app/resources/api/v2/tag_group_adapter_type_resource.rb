# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a tag group AdapterType
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagGroupAdapterTypeResource < BaseResource
      model_name 'TagGroup::AdapterType', add_model_hint: false

      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations:
      has_many :tag_groups, readonly: true, class_name: 'TagGroup'

      # Attributes
      attribute :name, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
    end
  end
end
