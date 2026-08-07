# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Sapio-specific Study resource for Integration Hub consumers.
      #
      # @note Access this resource via the `/api/v2/sapio/studies/` endpoint.
      # @note For index requests, this resource supports only filtering by name,
      # and it does not allow listing studies without a filter.
      #
      # @note The reference_genome relationship on studies is not accurate and
      #  not exposed in this resource. Use the reference_genome relationship on
      #  study_metadata instead.
      #
      # @note It does not subclass Api::V2::StudyResource to decouple it from
      #   the default Study resource, which is used by other API consumers.
      #
      # @example search studies by name
      #  GET /api/v2/sapio/studies?filter[name]=Test Study
      #
      # @example search studies by name with wildcards or exact phrases
      #  GET /api/v2/sapio/studies?filter[name]=*My "test and experiment" ?tudy*"Genomics"
      #
      # @example search studies by name and include study_metadata and study_metadata.reference_genome
      #  GET /api/v2/sapio/studies?filter[name]=My Study&include=study_metadata.reference_genome
      #
      # @example search studies, include study_metadata, and specify fields
      #  GET /api/v2/sapio/studies?filter[name]=My Study \
      #    &include=study_metadata.reference_genome
      #    &fields[studies]=name,uuid \
      #    &fields[study_metadata]=study_description,study_abstract
      #
      # @example GET request for a specific study by ID
      #  GET /api/v2/sapio/studies/123/
      #
      # TODO: Add update example(s)
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class StudyResource < Api::V2::BaseResource
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
        attribute :name, readonly: true

        # @!attribute [r] uuid
        #   @return [String] The UUID of the study.
        attribute :uuid, readonly: true

        # @!attribute [r] created_at
        #   @return [String] Timestamp when the study was created.
        attribute :created_at, readonly: true

        # @!attribute [r] updated_at
        #   @return [String] Timestamp when the study was last updated.
        #   @note study_metadata association specifies touch: true, so updated_at
        #     will reflect changes to the study_metadata as well.
        attribute :updated_at, readonly: true

        # @!attribute [r] blocked
        #   @return [Boolean] Whether the study is blocked.
        #   @note All rows in production have this column set to false.
        attribute :blocked, readonly: true

        # @!attribute [rw] state
        #   @return [String] The state of the study (pending, active, or inactive).
        attribute :state

        # @!attribute [rw] externally_managed
        #  @return [Boolean] Whether the study is managed by an external LIMS.
        attribute :externally_managed

        # @!attribute [r] ethically_approved
        #   @return [Boolean] Whether ethical approval is set.
        attribute :ethically_approved, readonly: true

        # @!attribute [r] enforce_data_release
        #   @return [Boolean] Whether data release enforcement is enabled.
        attribute :enforce_data_release, readonly: true

        # @!attribute [r] enforce_accessioning
        #   @return [Boolean] Whether accessioning enforcement is enabled.
        attribute :enforce_accessioning, readonly: true
      end
    end
  end
end
