# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {User}.
    #
    # {User} Represents Sequencescape users, used to regulate login as well as
    # provide tracking of who did what. While most users are internal, some are external.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/users/` endpoint.
    #
    # @example GET request for all users
    #   GET /api/v2/users/
    #
    # @example GET request for a user with ID 123
    #   GET /api/v2/users/123/
    #
    # For more information about JSON:API, refer to the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class UserResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The unique identifier for the user.
      #   @return [String] the UUID of the user.
      attribute :uuid, readonly: true

      # @!attribute [r] login
      #   The login identifier of the user, used to authenticate and identify the user.
      #   @return [String] the user's login identifier.
      attribute :login, readonly: true

      # @!attribute [r] first_name
      #   The user's first or given name.
      #   @return [String] the user's first name.
      attribute :first_name, readonly: true

      # @!attribute [r] last_name
      #   The user's last or surname.
      #   @return [String] the user's last name.
      attribute :last_name, readonly: true

      ###
      # Filters
      ###

      # @!method user_code
      #   A filter to return only users with the given user code.
      #   The user code will be compared with swipecodes and barcodes for users until matches are found.
      #   @example Filtering users by user code
      #     GET /api/v2/users?filter[user_code]=12345
      filter :user_code, apply: lambda { |records, value, _options| records.with_user_code(*value) }

      # @!method uuid
      #   A filter to return only users with the given UUID.
      #   @example Filtering users by UUID
      #     GET /api/v2/users?filter[uuid]=11111111-2222-3333-4444-555555666666
      filter :uuid, apply: lambda { |records, value, _options| records.with_uuid(*value) }
    end
  end
end
