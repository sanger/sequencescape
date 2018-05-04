require 'rails_helper'
RSpec.describe Api::V2::Aker::JobsController, type: :controller do
  context '#create' do
    it 'creates a new job' do
      post :create, params: {job: {}}
      binding.pry
      expect(response).to have_http_status(:created)
    end
  end
end