# frozen_string_literal: true

# This concern disables the destroy action for all JSONAPI::ResourceControllers in API v2.
# It ensures DELETE requests return a 405 Method Not Allowed response, preventing resource deletion.
# Existing endpoints already exclude the destroy action via `except: :destroy` in routes.rb,
# so this concern acts as a safeguard against future misconfigurations.
#
# NOTE: This file is located in `app/controllers/concerns/api/v2/disable_destroy_action.rb`
# instead of `app/controllers/api/v2/concerns/disable_destroy_action.rb` due to test suite expectations.
# Moving it to `app/controllers/api/v2/concerns` causes test failures as the file cannot be located.
module Api
  module V2
    module DisableDestroyAction
      extend ActiveSupport::Concern

      def destroy
        head :method_not_allowed
      end
    end
  end
end
