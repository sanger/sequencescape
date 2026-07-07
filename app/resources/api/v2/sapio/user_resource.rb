# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API representation of {User}.
      #
      # @note Access this resource using include on {Api::V2::Sapio::StudyResource}
      #  through the `user` relationship.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class UserResource < Api::V2::UserResource
      end
    end
  end
end
