# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Provides a JSON:API endpoint for Sapio to query Studies by name pattern.
      # This endpoint is feature-flagged and returns a limited result set (max 20 studies).
      class StudiesController < JSONAPI::ResourceController
        include Concerns::ApiKeyAuthenticatable
        include Api::V2::Concerns::ApiKeyAuthenticatable

        # The maximum allowed results for a single index query.
        MAX_RESULTS = 20

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

        def create
          study = Study.new(study_params)
          study.mastered_in_sapio = true

          if study.save
            render json: {
              data: {
                attributes: {
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
      end
    end
  end
end
