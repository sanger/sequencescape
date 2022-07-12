# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of custom_metadatum_collection
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class CustomMetadatumCollectionResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object, :custom_metadata

      # Associations:

      # Attributes
      attribute :uuid, readonly: true
      attribute :metadata #, readonly: true

      # This is required for POST
      attribute :user_id
      attribute :asset_id

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
