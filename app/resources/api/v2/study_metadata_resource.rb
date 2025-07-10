# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Study::Metadata} which contains additional
    # metadata related to a {Study}.
    #
    # A Study is a collection of various {Sample samples} and the work done on them.
    #
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class StudyMetadataResource < BaseResource
      immutable
      # NB: `study_metadata` has been added to `config/initializers/inflections.rb` to correctly
      # pluralize this class name. Without this, Rails would expect `StudyMetadatumResource`.
      #
      # `add_model_hint: true` is set to prevent 500 errors when updating from Limber, as it would
      # otherwise look for `Api::V2::MetadatumResource`.
      model_name 'Study::Metadata', add_model_hint: true

      ###
      # Attributes
      ###

      # @!attribute [r] faculty_sponsor
      #   @return [String] The faculty sponsor based on faculty_sponsor_id
      has_one :faculty_sponsor, foreign_key_on: :related, readonly: true
    end
  end
end
