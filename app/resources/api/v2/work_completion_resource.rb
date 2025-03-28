# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {WorkCompletion}

    # A WorkCompletion can be used to pass library creation requests.
    # It will also link the upstream and downstream requests to the correct receptacles.
    # The file contents are stored in the database using the {DbFile} model.

    # @note Access this resource via the `/api/v2/work_completions/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request to create a WorkCompletion (by uuids - deprecated)
    #   POST /api/v2/work_completions/
    #   {
    #     "data": {
    #       "type": "work_completions",
    #       "attributes": {
    #         "submission_uuids": ["11111111-2222-3333-4444-555555666666"],
    #         "target_uuid": "33333333-4444-5555-6666-777777888888",
    #         "user_uuid": "99999999-0000-1111-2222-333333444444"
    #       }
    #     }
    #   }
    #
    # @example POST request to create a WorkCompletion using relationships
    #   POST /api/v2/work_completions/
    #   {
    #     "data": {
    #       "type": "work_completions",
    #       "relationships": {
    #         "submissions": {
    #             "data": [
    #               { "type": "submissions", "id": 1 }
    #             ]
    #         },
    #         "target": {
    #             "data": { "type": "labware", "id": 1 }
    #         },
    #         "user": {
    #             "data": { "type": "users", "id": 4 }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all WorkCompletion resources
    #   GET /api/v2/work_completions/
    #
    # @example GET request for a WorkCompletion with ID 123
    #   GET /api/v2/work_completions/123/
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
      #   @param value [Array<String>] The UUIDs of the {Submission}s related to this WorkCompletion.
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
      #   @param value [String] The UUID of the {User} who initiated this work completion.
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
      #   An array of submissions which will be passed (although this is done through the request ids on the aliquots,
      #     not directly through the submissions).
      #   Setting this relationship alongside the `submission_uuids` attribute will override the attribute value.
      #   @return [Array<SubmissionResource>] The Submissions related to this WorkCompletion.
      #   @note This relationship is required.
      has_many :submissions, write_once: true

      # @!attribute [rw] target
      #   The labware on which the library has been completed.
      #   Setting this relationship alongside the `target_uuid` attribute will override the attribute value.
      #   @return [LabwareResource] The Labware which this WorkCompletion is associated with.
      #   @note This relationship is required.
      has_one :target, write_once: true

      # @!attribute [rw] user
      #   The user performing the action
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The User who initiated this WorkCompletion.
      #   @note This relationship is required.
      has_one :user, write_once: true
    end
  end
end
