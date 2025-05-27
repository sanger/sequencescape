# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V2::DisableDestroyAction, type: :controller do
  controller(ActionController::Base) { include Api::V2::DisableDestroyAction }

  before { routes.draw { delete 'destroy' => 'anonymous#destroy' } }

  describe 'DELETE #destroy' do
    it 'returns 405 Method Not Allowed' do
      delete :destroy
      expect(response).to have_http_status(:method_not_allowed)
    end
  end
end
