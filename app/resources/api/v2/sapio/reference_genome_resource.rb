# frozen_string_literal: true
module Api
  module V2
    module Sapio
      # Provides a JSON:API representation of {ReferenceGenome}.
      #
      # @note Access this resource using include on {Api::V2::Sapio::StudyResource}
      #  through the `study_metadata.reference_genome` relationship.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class ReferenceGenomeResource < Api::V2::BaseResource
        immutable

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String] The name of the reference genome.
        attribute :name

        # @!attribute [r] uuid
        #   @return [String] The UUID of the reference genome.
        attribute :uuid

        # @!attribute [r] created_at
        #   @return [String] Timestamp when the reference genome was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String] Timestamp when the reference genome was last updated.
        attribute :updated_at
      end
    end
  end
end
