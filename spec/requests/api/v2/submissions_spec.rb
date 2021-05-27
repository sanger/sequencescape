# frozen_string_literal: true

require 'rails_helper'

describe 'Submissions API', with: :api_v2 do
  context 'with multiple submissions' do
    before { create_list(:submission, 5) }

    it 'sends a list of submissions' do
      api_get '/api/v2/submissions'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a submission' do
    let(:resource_model) { create :submission }

    it 'sends an individual submission without tags' do
      api_get "/api/v2/submissions/#{resource_model.id}?fields[submissions]"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('submissions')
      expect(json.dig('data', 'attributes', 'used_tags')).to eq(nil)
    end

    it 'sends an individual submission without tags' do
      api_get "/api/v2/submissions/#{resource_model.id}?fields[submissions]=used_tags,name"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('submissions')
      expect(json.dig('data', 'attributes', 'used_tags')).to eq(resource_model.used_tags)
      expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
    end
  end
end
