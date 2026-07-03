# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API representation of {Program}.
      #
      # @note Access this resource using include on {Api::V2::Sapio::StudyResource}
      #  through the `study_metadata.program` relationship.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class ProgramResource < Api::V2::BaseResource
        immutable

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String, nil] Program name.
        attribute :name

        # @!attribute [r] created_at
        #   @return [String, nil] Timestamp when the program was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String, nil] Timestamp when the program was last updated.
        attribute :updated_at
      end
    end
  end
end
