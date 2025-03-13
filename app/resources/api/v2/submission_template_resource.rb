# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {SubmissionTemplate}.
    #
    # A {SubmissionTemplate} associates a name to a pre-filled submission (subclass) and a serialized set of attributes
    # A `SubmissionTemplate` is typically used to standardize submission parameters, making it easier to
    #   create new submissions
    # with predefined settings. Users can retrieve submission templates to understand their configurations.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/submission_templates/` endpoint.
    #
    # @example GET request for all SubmissionTemplate resources
    #   GET /api/v2/submission_templates/
    #
    # @example GET request for a SubmissionTemplate with a specific ID
    #   GET /api/v2/submission_templates/{id}
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SubmissionTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned and cannot be modified.
      #   @return [String] The UUID of the submission template.
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #   @return [String] The name of the submission template.
      attribute :name
    end
  end
end
