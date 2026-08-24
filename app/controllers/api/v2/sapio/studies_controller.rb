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

        # Before create study, authorize requests from Integration Hub API keys only.
        before_action :authorize_integration_hub!, only: [:create]

        # Enforces a name search constraint on resource index listing.
        #
        # @return [void]
        def index
          return render_feature_flag_disabled unless feature_flag_enabled?
          return render_missing_search_param unless search_param_present?

          super
        end

        # Displays details for a single study resource.
        #
        # @return [void]
        def show
          return render_feature_flag_disabled unless feature_flag_enabled?

          super
        end

        # Creates a new Study that is mastered in Sapio (externally_managed: true)
        # from the Integration Hub payload and grants ownership to the requesting user.
        #
        # @note This endpoint is intended exclusively for creating *new* studies that
        #   originate in Sapio. It should NOT be used to transfer an existing
        #   Sequencescape study to Sapio — use the update (PATCH) endpoint
        #   for that purpose, which sets +externally_managed+ on an existing record.
        #
        # @note Requires an Integration Hub API key. All other callers will receive
        #   a 403 Forbidden response.
        #
        # @note Requires the +:y26_172_enable_externally_managed_study_restrictions+
        #   feature flag to be enabled. Returns 404 otherwise.
        #
        # == Expected Payload
        #
        # The request body must be a JSON object with a top-level +study+ key:
        #
        #   POST /api/v2/sapio/studies
        #   Content-Type: application/json
        #   X-Sequencescape-Client-Id: <integration_hub_api_key>
        #
        # {
        #   "study": {
        #     "name": "(required) Unique study name, max 200 chars",
        #     "uuid": "(required) UUID to assign to the study, must be a valid UUID string"
        #   }
        # }
        #
        # == Responses
        #
        # [201 Created]     Study created successfully. Body contains +id+, +uuid+, +name+, and a +self+ link.
        # [403 Forbidden]   Missing or non-Integration Hub API key.
        # [404 Not Found]   Feature flag disabled.
        # [422 Unprocessable Entity] Validation failed (e.g. missing +name+). Body contains +errors+ array.
        #
        # @return [void]
        def create
          return render_feature_flag_disabled unless externally_managed_study_restrictions_enabled?

          study = build_sapio_study
          if study.save
            assign_supplied_uuid(study)
            render_study_created(study)
          else
            render json: { errors: study.errors.full_messages }, status: :unprocessable_content
          end
        end

        private

        # Ensures that the request is authorized with an Integration Hub API key.
        def authorize_integration_hub!
          return if @api_application&.integration_hub?

          render status: :forbidden,
                 json: {
                   errors: [
                     {
                       title: 'Forbidden',
                       detail: 'Integration Hub API key required.'
                     }
                   ]
                 }
        end

        # Builds and configures a new Study instance from the Sapio payload.
        def build_sapio_study
          Study.new(study_params).tap do |study|
            study.externally_managed = true
            study.skip_externally_managed_restriction = true
            study.lazy_metadata = true
            study.lazy_uuid_generation = true if sapio_study_payload[:uuid].present?
          end
        end

        # Assigns the UUID supplied by Integration Hub, skipping auto-generation.
        # Only runs if a UUID was included in the payload.
        def assign_supplied_uuid(study)
          supplied_uuid = sapio_study_payload[:uuid]
          return if supplied_uuid.blank?

          study.create_uuid_object!(external_id: supplied_uuid)
        end

        # Renders the 201 Created response for a successfully saved study.
        def render_study_created(study)
          render json: {
            data: {
              attributes: { id: study.id, uuid: study.uuid, name: study.name },
              links: { self: api_v2_sapio_study_url(study) }
            }
          }, status: :created
        end

        # Builds the top-level attributes hash passed to +Study.new+.
        def study_params
          { name: sapio_study_payload[:name] }
        end

        # Permits and memoizes the Sapio study payload parameters.
        def sapio_study_payload
          @sapio_study_payload ||= params.expect(study: %i[name uuid])
        end

        # Checks whether the Sapio studies endpoint feature flag is enabled.
        #
        # @return [Boolean] true if the +:y26_170_sapio_studies_endpoint+ flag is enabled
        def feature_flag_enabled?
          Flipper.enabled?(:y26_170_sapio_studies_endpoint)
        end

        # Checks whether the Sapio managed study restrictions feature flag is enabled.
        #
        # @return [Boolean] true if the +:y26_172_enable_externally_managed_study_restrictions+ flag is enabled
        def externally_managed_study_restrictions_enabled?
          Flipper.enabled?(:y26_172_enable_externally_managed_study_restrictions)
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
        def render_feature_flag_disabled
          render_errors(Errors::FeatureDisabled.new.errors)
        end

        # Renders a standardized JSON:API error for a missing search parameter.
        #
        # @return [void]
        def render_missing_search_param
          render_errors(Errors::MissingSearchParam.new.errors)
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
    end
  end
end
