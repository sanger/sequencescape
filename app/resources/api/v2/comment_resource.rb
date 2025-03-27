# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Comment}, which represents user-generated comments on various entities.
    #
    # @note Access this resource via the `/api/v2/comments/` endpoint.
    #
    # @example GET request for all Comment resources
    #   GET /api/v2/comments/
    #
    # @example GET request for a specific Comment by ID
    #   GET /api/v2/comments/123/
    #
    # @example POST request to create a new Comment
    #   POST /api/v2/comments/
    #
    # @example POST request body to create a new Comment
    #   {
    #     "data": {
    #       "type": "comments",
    #       "attributes": {
    #         "title": "Feedback",
    #         "description": "This is a great feature!"
    #       },
    #       "relationships": {
    #         "user": {
    #           "data": { "type": "users", "id": 4 }
    #         },
    #         "commentable": {
    #           "data": { "type": "wells", "id": "1" }
    #         }
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class CommentResource < BaseResource
      ###
      # Associations
      ###

      # @!attribute [rw] user
      #   @return [UserResource] The user who created the comment.
      has_one :user

      # @!attribute [rw] commentable
      #   @note This relationship is required.
      #   @return [ApplicationResource] The entity (e.g., article, post) to which this comment belongs.
      #   This is a polymorphic association, meaning it can be linked to multiple different models.
      has_one :commentable, polymorphic: true

      ###
      # Attributes
      ###

      # @!attribute [rw] title
      #   @note This attribute is required.
      #   @note This attribute is write_once; this attribute cannot be updated.
      #   @param value [String] The title of the comment.
      #   @return [String] The title of the comment.
      attribute :title, write_once: true

      # @!attribute [rw] description
      #   @note This attribute is required.
      #   @note This attribute is write_once; this attribute cannot be updated.
      #   @param value [String] The main content of the comment.
      #   @return [String] The main content of the comment.
      attribute :description, write_once: true

      # @!attribute [r] created_at
      #   @note This attribute is read-only.
      #   @return [DateTime] The timestamp when the comment was created.
      attribute :created_at, readonly: true

      # @!attribute [r] updated_at
      #   @note This attribute is read-only.
      #   @return [DateTime] The timestamp when the comment was last updated.
      attribute :updated_at, readonly: true
    end
  end
end
