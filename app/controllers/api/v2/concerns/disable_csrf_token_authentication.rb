# frozen_string_literal: true
module Api
  module V2
    module Concerns
      # This concern disables CSRF token authentication for all JSONAPI::ResourceControllers
      # Added as inserts/updates were causing the following exception:
      #
      # ActionController::InvalidAuthenticityToken (ActionController::InvalidAuthenticityToken):
      # Can't verify CSRF token authenticity
      #
      # NB. APi key authentication is still in place, so the API is still secure.
      # Longer term solution is to rework the security of the v2 API.
      module DisableCSRFTokenAuthentication
        extend ActiveSupport::Concern

        included { skip_before_action :verify_authenticity_token }
      end
    end
  end
end
