# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of a {SubmissionPool}.
    # SubmissionPools are designed to view submissions in the context of a particular labware.
    #
    # @example GET request for all SubmissionPool resources
    #   GET /api/v2/submission_pools/
    #
    # @example GET request for a SubmissionPool with ID 123
    #   GET /api/v2/submission_pools/123/
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/submission_pools/` endpoint.
    #
    # Provides a JSON:API representation of {SubmissionPool}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SubmissionPoolResource < BaseResource
      immutable

      # @!attribute [r] plates_in_submission
      #   @return [Integer] The number of plates in the submission pool.
      attribute :plates_in_submission, readonly: true

      # @!attribute [r] tag_layout_templates
      #   @return [Array<TagLayoutTemplateResource>] The tag layout templates for this submission pool.
      has_many :tag_layout_templates, readonly: true
    end
  end
end
