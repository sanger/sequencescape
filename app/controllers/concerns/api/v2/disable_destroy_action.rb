# frozen_string_literal: true
# This concern overrides the destroy method to do nothing for API v2 JSONAPI controllers

# This concern disables the destroy action for all JSONAPI::ResourceControllers in API v2.
# Prevents the deletion of resources via the API.

# This concern is a safety net for future misconfiguration, not for existing endpoints,
# which have the `except: :destroy` option set in the routes.rb file.
# This means Rails does not generate a route for DELETE, so a DELETE request results in an
# ActionController::RoutingError before the controller (and thus this concern) is ever invoked.

# Note: This file is located in `app/controllers/concerns/api/v2/disable_destroy_action.rb`
# instead of `app/controllers/api/v2/concerns/disable_destroy_action.rb` because the test suite
# expects it to be in this location. Placing it in `app/controllers/api/v2/concerns` caused
# the test `spec/controllers/concerns/api/v2/disable_destroy_action_spec.rb` to fail, as it
# could not locate the concern in the expected path.
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
