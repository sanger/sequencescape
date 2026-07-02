# frozen_string_literal: true

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

        # Enforces a name search constraint on resource index listing.
        #
        # @return [void]
        def index
          return render_feature_flag_disabled if feature_flag_disabled?
          return render_missing_search_param if search_param_missing?

          super
        end

        # Displays details for a single study resource.
        #
        # @return [void]
        def show
          return render_feature_flag_disabled if feature_flag_disabled?

          super
        end

        private

        # Checks whether the Sapio studies endpoint feature flag is inactive.
        #
        # @return [Boolean] true if the +:y26_170_sapio_studies_endpoint+ flag is disabled
        def feature_flag_disabled?
          !Flipper.enabled?(:y26_170_sapio_studies_endpoint)
        end

        # Checks whether the required JSON:API search filter parameter is absent or blank.
        #
        # @return [Boolean] true if the filter[name] parameter is missing
        def search_param_missing?
          params.dig(:filter, :name).blank?
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
        #   - adds the optional +maxresults
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
