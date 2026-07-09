# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API endpoint for Sapio to query Studies by name pattern.
      # This endpoint is feature-flagged and returns a limited result set (max 20 studies).
      class StudiesController < JSONAPI::ResourceController
        include Concerns::ApiKeyAuthenticatable
        include Api::V2::Concerns::ApiKeyAuthenticatable

        # The range of valid values for the custom +maxResults+ query parameter
        # to override the default maximum number of search results returned by
        # the +index+ action (Api::V2::BaseResource::MAX_RESULTS).
        RESULTS_RANGE = 1..1000

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

        def create
          return render_feature_flag_disabled if sapio_mastered_study_restrictions_disabled?

          study = Study.new(study_params)
          study.mastered_in_sapio = true
          study.lazy_metadata = true

          if study.save
            render json: {
              data: {
                attributes: {
                  id: study.id,
                  uuid: study.uuid,
                  name: study.name
                },
                links: {
                  self: api_v2_sapio_study_url(study)
                }
              }
            }, status: :created
          else
            render json: { errors: study.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def study_params
          params.expect(study: [:name])
        end

        # Checks whether the Sapio studies endpoint feature flag is enabled.
        #
        # @return [Boolean] true if the +:y26_170_sapio_studies_endpoint+ flag is enabled
        def feature_flag_enabled?
          Flipper.enabled?(:y26_170_sapio_studies_endpoint)
        end

        # Checks whether the Sapio mastered study restrictions feature flag is inactive.
        #
        # @return [Boolean] true if the +:y26_172_enable_sapio_mastered_study_restrictions+ flag is disabled
        def sapio_mastered_study_restrictions_disabled?
          !Flipper.enabled?(:y26_172_enable_sapio_mastered_study_restrictions)
        end

        # Checks whether the required JSON:API search filter parameter is absent or blank.
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
