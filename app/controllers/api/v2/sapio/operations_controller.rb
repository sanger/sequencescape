# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Receives combined reception and work order requests from Integration
      # Hub.
      #
      # The payload is plain JSON rather than JSON:API, so this is a plain
      # controller rather than a JSON:API resource controller.
      #
      # The endpoint is behind the +y26_282_sapio_work_order_endpoint+
      # feature flag.
      class OperationsController < ApplicationController
        skip_before_action :login_required
        skip_before_action :verify_authenticity_token

        before_action :check_endpoint_enabled

        # Accepts a combined reception and work order request.
        #
        # @return [void]
        def create
          render json: {}, status: :accepted
        end

        private

        # Renders a not found error unless the feature flag is enabled.
        #
        # @return [void]
        def check_endpoint_enabled
          return if Flipper.enabled?(:y26_282_sapio_work_order_endpoint)

          render_errors(Errors::FeatureDisabled.new.errors)
        end

        # Renders JSON:API style errors with the status of the first error.
        #
        # @param errors [Array<JSONAPI::Error>] the errors to render
        # @return [void]
        def render_errors(errors)
          render json: { errors: errors.map(&:to_hash) },
                 status: errors.first.status.to_i
        end
      end
    end
  end
end
