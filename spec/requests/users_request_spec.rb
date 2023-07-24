# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create :user, password: 'password' }

  before { post '/login', params: { login: user.login, password: 'password' } }

  describe 'GET show' do
    it 'shows the users profile', :aggregate_failures do
      get "/profile/#{user.id}"
      expect(assigns(:printer_list)).to eq(
        BarcodePrinter.alphabetical.where(barcode_printer_type: BarcodePrinterType96Plate.all).pluck(:name)
      )
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET edit' do
    it 'shows the profile edit page', :aggregate_failures do
      get "/profile/#{user.id}/edit"
      expect(response).to render_template(:edit)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET study_reports' do
    it 'shows the users study reports', :aggregate_failures do
      get "/profile/#{user.id}/study_reports"
      expect(response).to render_template(:study_reports)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET projects' do
    it 'shows the users projects', :aggregate_failures do
      get "/profile/#{user.id}/projects"
      expect(response).to render_template(:projects)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH update' do
    it 'updates the users profile', :aggregate_failures do
      patch "/profile/#{user.id}", params: { user: { first_name: 'test', last_name: 'name' } }
      expect(response).to redirect_to("/profile/#{user.id}")
      expect(response).to have_http_status(:found)
    end
  end

  describe 'POST print_swipecard' do
    it 'finds the endpoint and redirects to users profile', :aggregate_failures do
      post "/profile/#{user.id}/print_swipecard", params: { swipecard: 'test-swipecard', printer: 'test-printer' }
      expect(response).to redirect_to("/profile/#{user.id}")
      expect(response).to have_http_status(:found)
    end
  end
end
