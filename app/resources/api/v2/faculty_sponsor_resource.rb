# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {FacultySponsor}
    #
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class FacultySponsorResource < BaseResource
      # @!attribute [rw] name
      #   @return [String] The name of the faculty sponsor.
      attribute :name
    end
  end
end
