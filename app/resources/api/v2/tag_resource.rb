# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of aliquot
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      # Associations:
      has_one :tag_group, class_name: 'TagGroup'

      # Attributes
      attribute :oligo, readonly: true
      attribute :map_id, readonly: true



      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
