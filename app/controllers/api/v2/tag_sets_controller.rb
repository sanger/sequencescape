# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for TagSet
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagSetsController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
      before_action :check_feature_flag

      private

      def check_feature_flag
        render json: { error: 'TagSets API is disabled' } unless Flipper.enabled?(:y24_220_enable_tag_set_api)
      end
    end
  end
end
