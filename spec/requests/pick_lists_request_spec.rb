# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'PickLists', type: :request do
  let(:user) { create :user, password: 'password' }

  before { post '/login', params: { login: user.login, password: 'password' } }

  describe 'GET index' do
    before { create_list :pick_list, 2 }

    it 'returns a list of pick-lists', :aggregate_failures do
      get '/pick_lists'
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET show' do
    let(:pick_list) { create :pick_list }

    it 'returns a pick-list', :aggregate_failures do
      get "/pick_lists/#{pick_list.id}"
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end
  end
end
