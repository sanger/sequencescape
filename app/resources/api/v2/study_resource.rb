# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Study}

    # A Study is a collection of various {Sample samples} and the work done on them.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/studies/` endpoint.
    #
    # @example GET request for all studies
    #   GET /api/v2/studies/
    #
    # @example GET request for a study with ID 123
    #   GET /api/v2/studies/123/
    #
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class StudyResource < BaseResource
      # This resource is immutable, meaning that no changes can be made via the API.
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   @return [String] The name of the study.
      attribute :name

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the study.
      attribute :uuid

      ###
      # Relationships
      ###

      # @!attribute [r] poly_metadata
      #   @return [Array<PolyMetadatumResource>] The polymorphic metadata associated with this study.
      #   This metadata allows for the flexible extension of study attributes.
      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      # @!attribute [rw] study_metadata
      #   @return [StudyMetadataResource] The metadata associated with this sample, containing additional
      #     details like faculty sponsor
      #   @note Optional relationship.
      has_one :study_metadata, class_name: 'StudyMetadata', foreign_key_on: :related

      ###
      # Filters
      ###

      # @!method filter_by_name(name)
      #   Allows filtering studies by their name.
      #   @example GET /api/v2/studies?filter[name]=Genomics Study
      #   @param name [String] The name of the study to filter by.
      filter :name

      # @!method filter_by_state(state)
      #   Allows filtering studies by their state (e.g., active, archived).
      #   @example GET /api/v2/studies?filter[state]=active
      #   @param state [String] The state of the study to filter by.
      filter :state, apply: lambda { |records, value, _options| records.by_state(value) }

      # @!method filter_by_user(user_id)
      #   Allows filtering studies by the user who owns or manages them.
      #   @example GET /api/v2/studies?filter[user]=456
      #   @param user_id [String] The ID of the user to filter by.
      filter :user, apply: lambda { |records, value, _options| records.by_user(value) }

      # @!method uuid
      #   A filter to return only studies with the given UUID.
      #   @example Filtering users by UUID
      #     GET /api/v2/studies?filter[uuid]=11111111-2222-3333-4444-555555666666
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
