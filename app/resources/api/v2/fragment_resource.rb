# frozen_string_literal: true

module Api
  module V2
    # This resource does not appear to be used; can it be deprecated?
    #
    # @note There is no access to this resource.
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class FragmentResource < JSONAPI::Resource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @return [String] The universally unique identifier (UUID) for this fragment.
      #   This identifier is automatically assigned upon creation and cannot be modified.
      attribute :uuid, readonly: true
    end
  end
end
