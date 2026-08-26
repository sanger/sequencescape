# frozen_string_literal: true

# NOTE: Before adding additional functionality here, confirm the same effect cannot be achieved using vanilla JSONAPI:
# - Idioms for controllers: https://jsonapi-resources.com/v0.10/guide/controllers.html
# - Idioms for resources: https://jsonapi-resources.com/v0.10/guide/resources.html

module Api
  module V2
    module Sapio
      # Provides a JSON:API endpoint for Sapio to query Studies by name pattern.
      # This endpoint is feature-flagged and returns a limited result set (max 20 studies).
      class StudiesController < JSONAPI::ResourceController
        include Concerns::ApiKeyAuthenticatable

        # The range of valid values for the custom +maxResults+ query parameter
        # to override the default maximum number of search results returned by
        # the +index+ action (Api::V2::BaseResource::MAX_RESULTS).
        RESULTS_RANGE = 1..1000

        before_action :check_sapio_studies_endpoint_enabled
        before_action :check_externally_managed_study_restrictions_enabled, only: [:create]
        # Before create study, authorize requests from Integration Hub API keys only.
        before_action :authorize_integration_hub, only: [:create]

        # Enforces a name search constraint on resource index listing.
        #
        # @return [void]
        def index
          return render_missing_search_param unless search_param_present?

          super
        end

        # Creates a new externally managed Study.
        #
        # It should NOT be used to transfer an existing Sequencescape study to Sapio.
        #
        # @return [void]
        def create
          super
        end

        private

        # Checks whether the Sapio studies endpoint feature flag is enabled.
        #
        # @return [void] Renders a standardized JSON:API error if the +y26_170_sapio_studies_endpoint+ feature flag
        # is disabled.
        def check_sapio_studies_endpoint_enabled
          render_feature_disabled unless Flipper.enabled?(:y26_170_sapio_studies_endpoint)
        end

        # Checks whether the Sapio managed study restrictions feature flag is enabled.
        #
        # @return [void] Renders a standardized JSON:API error if the
        # +y26_172_enable_externally_managed_study_restrictions+ feature flag is disabled.
        def check_externally_managed_study_restrictions_enabled
          render_feature_disabled unless Flipper.enabled?(:y26_172_enable_externally_managed_study_restrictions)
        end

        # Ensures that the request is authorized with an Integration Hub API key.
        def authorize_integration_hub
          render_forbidden unless @api_application&.integration_hub?
        end

        # Checks whether the required JSON:API search filter parameter is present?
        #
        # @return [Boolean] true if the filter[name] parameter is present
        def search_param_present?
          params.dig(:filter, :name).present?
        end

        # Renders a standardized JSON:API error for a disabled feature flag configuration.
        #
        # @return [void]
        def render_feature_disabled
          render_errors(Errors::FeatureDisabled.new.errors)
        end

        # Renders a standardized JSON:API error for a missing search parameter.
        #
        # @return [void]
        def render_missing_search_param
          render_errors(Errors::MissingSearchParam.new.errors)
        end

        # Renders a standardized JSON:API error for a forbidden request.
        #
        # @return [void]
        def render_forbidden
          render_errors(Errors::Forbidden.new.errors)
        end

        # Returns request context for JSONAPI::Resources, which is available
        # to the filter method in options[:context].
        #
        # For the +index+ action,
        #  - adds the optional +maxResults+ parameter if given, which is used
        #    to override the default maximum number of search results returned.
        #  - adds the untouched +filter[name]+ parameter, because JSONAPI
        #    strips the quotes by calling CSV.parse_line on it. We need the
        #    quotes if user is searching exact phrase.
        #
        # @note The +maxResults+ parameter uses the JSON:API naming for custom
        #   parameters.
        #
        # @return [Hash] Context passed to JSONAPI::Resources.
        def context
          context = super
          if action_name == 'index'
            max_results = params[:maxResults].to_i
            context[:max_results] = max_results if RESULTS_RANGE.cover?(max_results)
            context[:filter_name] = params.dig(:filter, :name)
          end
          context
        end
      end

      class StudyProcessor < JSONAPI::Processor
        before_create_resource :validate_uuid_format
        before_create_resource :validate_uuid_uniqueness

        private

        # Validates that the provided UUID is in a valid format.
        def validate_uuid_format
          return if external_uuid.blank? || Uuid.uuid?(external_uuid)

          raise JSONAPI::Exceptions::InvalidFieldValue.new(:uuid, external_uuid)
        end

        # Validate that the provided UUID is unique
        def validate_uuid_uniqueness
          return if external_uuid.blank?

          # Validation for unique UUID within the Study types
          return if Uuid.find_id(external_uuid).blank?

          raise JSONAPI::Exceptions::InvalidFieldValue.new(:uuid, 'This UUID already exists and')
        end

        def external_uuid
          @external_uuid ||= params.dig(:data, :attributes, :uuid)
        end
      end
    end
  end
end
