# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  describe 'GET #not_found' do
    before { get :not_found }

    it 'renders the not_found template' do
      expect(response).to render_template(:not_found)
    end

    it 'returns 404 status' do
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #internal_server' do
    before { get :internal_server }

    it 'renders the internal_server template' do
      expect(response).to render_template(:internal_server)
    end

    it 'returns 500 status' do
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe 'GET #service_unavailable' do
    before { get :service_unavailable }

    it 'renders the service_unavailable template' do
      expect(response).to render_template(:service_unavailable)
    end

    it 'returns 503 status' do
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
