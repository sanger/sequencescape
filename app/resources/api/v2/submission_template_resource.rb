# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/submission_templates/` endpoint.
    #
    # Provides a JSON:API representation of {SubmissionTemplate}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SubmissionTemplateResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [rw] name
      #   @return [String] the name of the submission template.
      attribute :name

      # @!attribute [r] uuid
      #   @return [String] the UUID of the submission template.
      attribute :uuid, readonly: true
    end
  end
end
