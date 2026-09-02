# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Sapio-specific Study resource for Integration Hub consumers.
      #
      # @note Access this resource via the `/api/v2/sapio/studies/` endpoint.
      #
      # @note Requires the +:y26_172_enable_externally_managed_study_restrictions+ feature flag to
      #   be enabled. Returns **404 Not Found** otherwise.
      #
      # @note Requests that modify data require a valid Integration Hub API key. If this key is not
      #   provided, the request will return a **403 Forbidden** response. See the examples for more
      #   details.
      #
      # @note It does not subclass `Api::V2::StudyResource` to decouple it from the default Study
      #   resource, which is used by other API consumers.
      #
      # @todo The `reference_genome` relationship on studies is not accurate and not exposed in this
      #  resource. Use the `reference_genome` relationship on study_metadata instead.
      #
      # == Indexing and Searching
      #
      # For index requests, this resource supports only filtering by name, and it does not allow
      # listing studies without a filter.
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
      #    &include=study_metadata.reference_genome \
      #    &fields[studies]=name,uuid \
      #    &fields[study_metadata]=study_description,study_abstract
      #
      # @example GET request for a specific study by ID
      #  GET /api/v2/sapio/studies/123/
      #
      # == Creating a New Externally Managed Study
      #
      # The POST method creates a new {Study} that is managed externally, granting ownership to the
      # requesting user.
      #
      # This method is intended exclusively for creating *new* studies that originate in an external
      # LIMS. It should NOT be used to transfer an existing Sequencescape study to the external LIMS.
      #
      # If a UUID is not provided, one will be generated automatically.
      #
      # @example POST request to create a new externally managed study
      #   POST /api/v2/sapio/studies
      #   Content-Type: application/json
      #   X-Sequencescape-Client-Id: <integration_hub_api_key>
      #   {
      #     "data": {
      #       "type": "studies",
      #       "attributes": {
      #         "name": "Unique study name, max 200 chars",
      #         "uuid": "11111111-2222-3333-4444-555555666666"
      #       }
      #     }
      #   }
      #
      # == Updating an Existing Study
      #
      # Existing studies can be updated using the PATCH method. Only studies that have been marked
      # as +externally_managed+ can be updated via this endpoint. Attempts to update a study that is
      # not externally managed will return a **423 Locked** response.
      #
      # @example PATCH request to update an existing study
      #   PATCH /api/v2/sapio/studies/123
      #   Content-Type: application/json
      #   X-Sequencescape-Client-Id: <integration_hub_api_key>
      #   {
      #     "data": {
      #       "type": "studies",
      #       "id": "123",
      #       "attributes": {
      #         "state": "active"
      #       }
      #     }
      #   }
      #
      # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
      # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
      # of the JSON:API standard.
      class StudyResource < Api::V2::BaseResource
        include Api::V2::Sapio::StudySearchQuery

        before_create :allow_changes, :prepare_study_for_external_management
        after_create :set_external_uuid

        before_update :allow_changes

        ###
        # Filters
        ###

        # Override the name filter from parent to support wildcard patterns
        # Accepts patterns like "my_study*" or "my_study?"
        filter :name, apply: method(:apply_name_filter)

        ###
        # Relationships
        ###

        # @!attribute [r] study_metadata
        #   @return [StudyMetadataResource] The metadata associated with this
        #     study, containing additional details like faculty sponsor
        has_one :study_metadata, class_name: 'StudyMetadata', foreign_key_on: :related

        # @!attribute [r] user
        #   @return [UserResource, nil] The user associated with this study.
        has_one :user, class_name: 'User', foreign_key_on: :self

        ###
        # Attributes
        ###

        # @!attribute [r] name
        #   @note This attribute is required when creating a new study.
        #   @note Cannot be updated after creation.
        #   @note Maximum length is 200 characters.
        #   @note Must be unique across all studies.
        #   @return [String] The name of the study.
        attribute :name, write_once: true

        # @!attribute [r] uuid
        #   A version 1 UUID that uniquely identifies the study.
        #   @note Cannot be updated after creation.
        #   @return [String] The UUID of the study.
        attribute :uuid, write_once: true

        def uuid=(external_uuid)
          # Setup resource to create the UUID after the study is saved, since the study must exist first
          @model.lazy_uuid_generation = true # Don't create the UUID on model creation
          context[:external_uuid] = external_uuid # Store the external UUID in the context to be used in after_create
        end

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

        # @!attribute [r] externally_managed
        #  @note Cannot be updated after creation.
        #  @return [Boolean] Whether the study is managed by an external LIMS.
        attribute :externally_managed, write_once: true

        # @!attribute [r] ethically_approved
        #   @return [Boolean] Whether ethical approval is set.
        attribute :ethically_approved, readonly: true

        # @!attribute [r] enforce_data_release
        #   @return [Boolean] Whether data release enforcement is enabled.
        attribute :enforce_data_release, readonly: true

        # @!attribute [r] enforce_accessioning
        #   @return [Boolean] Whether accessioning enforcement is enabled.
        attribute :enforce_accessioning, readonly: true

        private

        # Allow externally managed studies to be altered via the API
        def allow_changes
          @model.skip_externally_managed_restriction = true
        end

        # Sets the model flags required for externally-managed studies before saving.
        #
        # The lazy_metadata flag is set to true to avoid triggering the creation of a StudyMetadata record
        # and it's associated validations.
        #
        # @return [void]
        def prepare_study_for_external_management
          @model.externally_managed = true
          @model.lazy_metadata = true
        end

        # Sets the external UUID for the study if provided in the context.
        #
        # Links the externally provided UUID to the study once saved.
        #
        # @return [void]
        def set_external_uuid
          uuid = context[:external_uuid]
          return if uuid.blank?

          # Create the UUID and link it to the study.
          @model.create_uuid_object!(external_id: uuid)
        end
      end
    end
  end
end
