# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API representation of {StudyType}.
      #
      # @note Access this resource using include on {Api::V2::Sapio::StudyResource}
      #  through the `study_metadata.study_type` relationship.
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class StudyTypeResource < Api::V2::BaseResource
        immutable

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String, nil] Study type name.
        attribute :name

        # @!attribute [r] valid_type
        #   @return [Boolean, nil] Whether this is a valid study type.
        attribute :valid_type

        # @!attribute [r] created_at
        #   @return [String, nil] Timestamp when the study type was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String, nil] Timestamp when the study type was last updated.
        attribute :updated_at

        # @!attribute [r] valid_for_creation
        #   @return [Boolean] Whether this study type is valid for creation.
        attribute :valid_for_creation
      end
    end
  end
end
