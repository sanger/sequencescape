# This spec tests the behavior of the `Api::V2::DisableDestroyAction` concern,
# ensuring that the `destroy` action is disabled and returns a 405 Method Not Allowed response.
#
# The following line is added to dynamically define a controller that includes the concern:
# `controller(ActionController::Base) { include Api::V2::DisableDestroyAction }`
# This allows us to test the concern in isolation without relying on an existing controller.
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V2::Concerns::DisableDestroyAction, type: :controller do
  # We explicitly use the constant `Api::V2::DisableDestroyAction` here instead of `described_class`
  # because `described_class` is not accessible at the top level of the spec file where the
  # anonymous controller is being defined. Attempting to use `described_class` in this context
  # results in a NameError, as RSpec has not yet defined it. Therefore, we disable the RuboCop
  # RSpec/DescribedClass rule for this line only.
  # rubocop:disable RSpec/DescribedClass
  controller(ActionController::Base) { include Api::V2::Concerns::DisableDestroyAction }
  # rubocop:enable RSpec/DescribedClass

  before { routes.draw { delete 'destroy' => 'anonymous#destroy' } }

  describe 'DELETE #destroy' do
    it 'returns 405 Method Not Allowed' do
      delete :destroy
      expect(response).to have_http_status(:method_not_allowed)
    end
  end
end
