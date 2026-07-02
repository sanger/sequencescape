# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Sapio-specific Study resource for Integration Hub consumers.
      #
      # @note The reference_genome relationship on studies is not accurate.
      #   Use the reference_genome relationship on study_metadata instead.
      #
      # @note It does not subclass Api::V2::StudyResource to decouple it from
      #   the default Study resource, which is used by other API consumers.
      class StudyResource < Api::V2::BaseResource
        immutable # Read-only is enough for the Sapio study search story.

        include Api::V2::Sapio::StudySearchQuery

        ##
        # Filters
        #

        # Override the name filter from parent to support wildcard patterns
        # Accepts patterns like "my_study*" or "my_study?"
        filter :name, apply: method(:apply_name_filter)

        ##
        # Relationships
        #

        # @!attribute [r] study_metadata
        #   @return [StudyMetadataResource] The metadata associated with this
        #     study, containing additional details like faculty sponsor
        has_one :study_metadata, class_name: 'StudyMetadata', foreign_key_on: :related

        # @!attribute [r] user
        #   @return [UserResource, nil] The user associated with this study.
        has_one :user, class_name: 'User', foreign_key_on: :self

        ##
        # Attributes
        #

        # @!attribute [r] name
        #   @return [String] The name of the study.
        attribute :name

        # @!attribute [r] uuid
        #   @return [String] The UUID of the study.
        attribute :uuid

        # @!attribute [r] created_at
        #   @return [String] Timestamp when the study was created.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String] Timestamp when the study was last updated.
        #   @note study_metadata association specifies touch: true, so updated_at
        #     will reflect changes to the study_metadata as well.
        attribute :updated_at

        # @!attribute [r] blocked
        #   @return [Boolean] Whether the study is blocked.
        #   @note All rows in production have this column set to false.
        attribute :blocked

        # @!attribute [r] state
        #   @return [String] The state of the study (pending, active, or inactive).
        attribute :state

        # @!attribute [r] ethically_approved
        #   @return [Boolean] Whether ethical approval is set.
        attribute :ethically_approved

        # @!attribute [r] enforce_data_release
        #   @return [Boolean] Whether data release enforcement is enabled.
        attribute :enforce_data_release

        # @!attribute [r] enforce_accessioning
        #   @return [Boolean] Whether accessioning enforcement is enabled.
        attribute :enforce_accessioning
      end
    end
  end
end
