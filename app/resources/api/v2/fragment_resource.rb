# frozen_string_literal: true

module Api
  module V2
    # @todo There is no access to this resource. To add access, you would need to
    #   add a route to the `routes.rb` file and create a controller for it. Or
    #   if this resource is not to be used, can it be deprecated?
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
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
