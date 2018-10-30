# frozen_string_literal: true

require 'rails_helper'

describe 'Submissions API', with: :api_v2 do
  context 'with multiple submissions' do
    before do
      create_list(:submission, 5)
    end

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

    it 'sends an individual submission' do
      api_get "/api/v2/submissions/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('submissions')
    end

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'submissions',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    # Remove if immutable
    it 'allows update of a submission' do
      api_patch "/api/v2/submissions/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('submissions')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
