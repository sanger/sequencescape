# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/users/` endpoint.
    #
    # Provides a JSON:API representation of {User}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class UserResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @return [String] the UUID of the user.
      attribute :uuid, readonly: true

      # @!attribute [r] login
      #   @return [String] the user's login identifier.
      attribute :login, readonly: true

      # @!attribute [r] first_name
      #   @return [String] the user's first/given name.
      attribute :first_name, readonly: true

      # @!attribute [r] last_name
      #   @return [String] the user's last/surname.
      attribute :last_name, readonly: true

      ###
      # Filters
      ###

      # @!method user_code
      #   A filter to return only users with the given user code.
      #   The given user code will be compared with the swipecodes and barcodes for users until matches are found.
      filter :user_code, apply: lambda { |records, value, _options| records.with_user_code(*value) }

      # @!method uuid
      #   A filter to return only users with the given UUID.
      filter :uuid, apply: lambda { |records, value, _options| records.with_uuid(*value) }
    end
  end
end
