# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # Provides a JSON:API representation of {WorkCompletion} which contains the QC data previously added to a piece of
    # {Labware}. The file contents are stored in the database using the {DbFile} model.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/work_completions/` endpoint.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class WorkCompletionResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] submission_uuids
      #   This is declared for convenience where the submissions are not available to set as a relationship.
      #   Setting this attribute alongside the `submissions` relationships will prefer the relationship value.
      #   @deprecated Use the `submissions` relationship instead.
      #   @param value [Array<String>] The UUIDs of the [{Submission}s] related to this WorkCompletion.
      #   @return [Void]
      #   @see #submissions
      attribute :submission_uuids, writeonly: true

      def submission_uuids=(value)
        @model.submissions = value.map { |v| Submission.with_uuid(v).first }
      end

      # @!attribute [w] target_uuid
      #   This is declared for convenience where the target {Labware} is not available to set as a relationship.
      #   Setting this attribute alongside the `target` relationship will prefer the relationship value.
      #   @deprecated Use the `target` relationship instead.
      #   @param value [String] The UUID of the {Labware} that this work completion targets.
      #   @return [Void]
      #   @see #target
      attribute :target_uuid, writeonly: true

      def target_uuid=(value)
        @model.target = Labware.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the {User} who initiated this plate creation.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      ###
      # Relationships
      ###

      # @!attribute [rw] submissions
      #   Setting this relationship alongside the `submission_uuids` attribute will override the attribute value.
      #   @return [Array<SubmissionResource>] The Submissions related to this WorkCompletion.
      #   @note This relationship is required.
      has_many :submissions, write_once: true

      # @!attribute [rw] target
      #   Setting this relationship alongside the `target_uuid` attribute will override the attribute value.
      #   @return [LabwareResource] The Labware which this WorkCompletion targets. @todo: reword to active sense
      #   @note This relationship is required.
      has_one :target, write_once: true

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The User who initiated this WorkCompletion.
      #   @note This relationship is required.
      has_one :user, write_once: true
    end
  end
end
