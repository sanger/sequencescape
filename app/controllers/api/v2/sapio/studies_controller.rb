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
          render_jsonapi_errors(
            [
              {
                status: :not_found,
                code: 'FEATURE_DISABLED',
                title: 'Not Found',
                detail: 'This endpoint is not currently available.'
              }
            ]
          )
        end

        # Renders a standardized JSON:API error for a missing search parameter.
        #
        # @return [void]
        def render_missing_search_parameter
          render_jsonapi_errors(
            [
              {
                status: :bad_request,
                code: 'MISSING_SEARCH_PARAMETER',
                title: 'Missing Search Parameter',
                detail: 'Listing all resources is disabled. You must provide a "name" search parameter.',
                source: { parameter: 'filter[name]' }
              }
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
          render_jsonapi_errors(
            [
              {
                status: :unprocessable_entity,
                code: 'RESULT_SET_TOO_LARGE',
                title: 'Result set too large',
                detail: detail_message
              }
            ]
          )
        end

        # Renders multiple JSON:API error payloads in a single document collection.
        # If a header status is not provided, it infers it from the first error's status.
        #
        # @param errors_array [Array<Hash>] collection of error specification hashes
        # @param status [Symbol, Integer, nil] the HTTP response header status
        #
        # @note Each hash in the +errors_array+ accepts the following options:
        # @option errors_array [Symbol, Integer, String] :status (nil) error-specific status override
        # @option errors_array [String, Symbol] :code an application-specific code identifier
        # @option errors_array [String] :title a short summary description of the problem
        # @option errors_array [String] :detail a contextual human-readable explanation
        # @option errors_array [Hash] :source (nil) reference parameters or JSON pointers to error origins
        #
        # @see https://jsonapi.org/format/#error-objects for JSON:API error object specification
        # @return [void]
        def render_jsonapi_errors(errors_array, status: nil)
          resolved_status = status || errors_array.first&.[](:status) || :unprocessable_entity
          fallback_code = numeric_status_for(resolved_status)

          formatted_errors = errors_array.map do |error|
            serialize_jsonapi_error(error, fallback_code)
          end

          render status: resolved_status, json: { errors: formatted_errors }
        end

        # Maps an internal error hash into standard JSON:API formatting structures.
        #
        # @param error [Hash] individual validation metadata attributes
        # @param fallback_code [String] status identifier used if error is missing explicit code
        # @return [Hash]
        def serialize_jsonapi_error(error, fallback_code)
          status_code = error[:status] ? numeric_status_for(error[:status]) : fallback_code

          {
            status: status_code,
            code: error[:code].to_s.upcase,
            title: error[:title],
            detail: error[:detail]
          }.tap do |hash|
            hash[:source] = error[:source] if error[:source].present?
          end
        end

        # Converts a status symbol into its corresponding numeric string.
        #
        # @param status [Symbol, Integer, String] target error code identifier
        # @return [String]
        def numeric_status_for(status)
          Rack::Utils::SYMBOL_TO_STATUS_CODE[status]&.to_s || status.to_s
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
