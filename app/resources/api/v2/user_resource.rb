# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of user
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
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
