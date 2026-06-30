# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API endpoint for Sapio to query Studies by name pattern.
      # This endpoint is feature-flagged and returns a limited result set (max 20 studies).
      class StudiesController < JSONAPI::ResourceController
        include Concerns::ApiKeyAuthenticatable

        # The maximum allowed results for a single index query.
        MAX_RESULTS = 20

        # Enforces a name search constraint on resource index listing.
        #
        # @return [void]
        def index
          return render_feature_flag_disabled if feature_flag_disabled?
          return render_missing_search_parameter if search_query_missing?
          # XXX: Move the following to resource layer
          return render_result_set_too_large(matching_studies_count) if matching_studies_count > MAX_RESULTS

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
        def search_query_missing?
          params.dig(:filter, :name).blank?
        end

        # Renders a standardized JSON:API error for a disabled feature flag configuration.
        #
        # @return [void]
        def render_feature_flag_disabled
          render_errors(
            [
              JSONAPI::Error.new(
                status: :not_found,
                title: 'Not Found',
                code: 'FEATURE_DISABLED',
                detail: 'This endpoint is not currently available.'
              )
            ]
          )
        end

        # Renders a standardized JSON:API error for a missing search parameter.
        #
        # @return [void]
        def render_missing_search_parameter
          render_errors(
            [
              JSONAPI::Error.new(
                status: :bad_request,
                title: 'Missing Search Parameter',
                code: 'MISSING_SEARCH_PARAMETER',
                detail: 'Listing all resources is disabled. You must provide a "name" search parameter.',
                source: { parameter: 'filter[name]' }
              )
            ]
          )
        end

        # Renders a standardized JSON:API error when query matches exceed required limit.
        #
        # @param count [Integer] the total number of records matched by the query
        # @return [void]
        def render_result_set_too_large(count)
          detail_message = "Your search matched at least #{count} studies. " \
                           'Please refine your query to return 20 or fewer results.'

          render_errors(
            [
              JSONAPI::Error.new(
                status: :unprocessable_entity,
                title: 'Result set too large',
                code: 'RESULT_SET_TOO_LARGE',
                detail: detail_message
              )
            ]
          )
        end

        # Counts matching elements up to safety boundary, i.e. +MAX_RESULTS + 1+.
        #
        # @return [Integer]
        def matching_studies_count
          matching_studies_scope.limit(MAX_RESULTS + 1).pluck(:id).size
        end

        # Evaluates applicable search scope configurations.
        #
        # @return [ActiveRecord::Relation]
        def matching_studies_scope
          query = normalized_name_filter
          return Study.all if query.blank?

          if query.include?('*') || query.include?('?')
            apply_wildcard_studies_scope(query)
          else
            apply_exact_studies_scope(query)
          end
        end

        # Filters records based on wildcard parameters.
        #
        # @param query [String] sanitized query text
        # @return [ActiveRecord::Relation]
        def apply_wildcard_studies_scope(query)
          pattern = query.gsub('\\', '\\\\').gsub('%', '\\%').gsub('_', '\\_').tr('*', '%').tr('?', '_')
          Study.where("studies.name LIKE :pattern ESCAPE '\\\\'", pattern:)
        end

        # Filters records based on exact match and similarity index rules.
        #
        # @param query [String] sanitized query text
        # @return [ActiveRecord::Relation]
        def apply_exact_studies_scope(query)
          escaped_query = query.gsub(/[%_\\]/) { |char| "\\#{char}" }
          sql_clause = 'studies.name = :exact OR ' \
                       "studies.name LIKE :partial ESCAPE '\\\\' OR " \
                       'SOUNDEX(studies.name) = SOUNDEX(:query)'

          Study.where(sql_clause, exact: query, partial: "%#{escaped_query}%", query: query)
        end

        # Sanitizes input strings extracted from parameters
        #
        # @return [String]
        def normalized_name_filter
          raw_filter = params.fetch(:filter, {})
          raw_name = raw_filter[:name] || raw_filter['name']
          query = (raw_name.is_a?(Array) ? raw_name.first : raw_name).to_s.strip
          query.delete_prefix('"').delete_suffix('"')
        end
      end
    end
  end
end
