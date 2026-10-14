# frozen_string_literal: true

module Api
  module V2
    module Sapio
      # Receives combined reception and work order requests from Integration
      # Hub.
      #
      # The payload is plain JSON rather than JSON:API, so this is a plain
      # controller rather than a JSON:API resource controller.
      class OperationsController < ApplicationController
        skip_before_action :login_required
        skip_before_action :verify_authenticity_token

        # Accepts a combined reception and work order request.
        #
        # @return [void]
        def create
          render json: {}, status: :accepted
        end
      end
    end
  end
end
