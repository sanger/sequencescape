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

        def create
          return render_feature_flag_disabled unless sapio_mastered_study_restrictions_enabled?

          study = build_sapio_study
          if study.save
            grant_study_owner(study)
            render_study_created(study)
          else
            render json: { errors: study.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

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

        # Builds and configures a new +Study+ instance from the Sapio payload.
        def build_sapio_study
          Study.new(study_params).tap do |study|
            study.mastered_in_sapio = true
            study.bypass_sapio_validation = true
            study.lazy_metadata = true
          end
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
          { name: sapio_study_payload[:name], study_metadata_attributes: study_metadata_params }
        end

        # Merges direct scalar metadata fields with association ID lookups.
        def study_metadata_params
          study_metadata_direct_params.merge(study_metadata_association_ids)
        end

        # Scalar metadata fields that are passed through from the Sapio payload without lookup.
        def study_metadata_direct_params
          payload = sapio_study_payload
          {
            study_study_title: payload[:title],
            study_description: payload[:study_description],
            study_abstract: payload[:abstract],
            data_release_strategy: payload[:data_release_strategy]
          }
        end

        # Resolves Sapio name fields to Sequencescape association IDs.
        def study_metadata_association_ids
          payload = sapio_study_payload
          {
            faculty_sponsor_id: FacultySponsor.find_by(name: payload[:faculty_sponsor])&.id,
            program_id: Program.find_by(name: payload[:program])&.id,
            study_type_id: StudyType.find_by(name: payload[:study_type])&.id,
            data_release_study_type_id: DataReleaseStudyType.find_by(name: payload[:data_release_study_type])&.id
          }
        end

        # Permits and memoizes the Sapio study payload parameters.
        def sapio_study_payload
          @sapio_study_payload ||= params.expect(
            study: %i[
              name
              study_owner_name
              faculty_sponsor
              program
              title
              study_type
              data_release_study_type
              study_description
              abstract
              data_release_strategy
            ]
          )
        end

        # Grants the owner role to the user identified by +study_owner_name+ (login).
        # Silently skips if the field is absent or no matching user is found.
        def grant_study_owner(study)
          owner_name = sapio_study_payload[:study_owner_name]
          return if owner_name.blank?

          owner = User.find_by(login: owner_name)
          owner&.grant_owner(study)
        end

        # Checks whether the Sapio studies endpoint feature flag is enabled.
        #
        # @return [Boolean] true if the +:y26_170_sapio_studies_endpoint+ flag is enabled
        def feature_flag_enabled?
          Flipper.enabled?(:y26_170_sapio_studies_endpoint)
        end

        # Checks whether the Sapio mastered study restrictions feature flag is enabled.
        #
        # @return [Boolean] true if the +:y26_172_enable_sapio_mastered_study_restrictions+ flag is enabled
        def sapio_mastered_study_restrictions_enabled?
          Flipper.enabled?(:y26_172_enable_sapio_mastered_study_restrictions)
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
