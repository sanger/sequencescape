# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Studies API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/studies' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple studies' do
    let!(:study) { create(:study) }

    before do
      create(:study)
      create(:study)
    end

    it 'sends a list of studies' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(Study.count)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
    it 'filters studies by name' do
      api_get "#{base_endpoint}?filter[name]=\"#{study.name}\""
      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(1)
      expect(json['data'][0]['attributes']['uuid']).to eq(study.uuid)
    end

    it 'filters studies by uuid' do
      api_get "#{base_endpoint}?filter[name]=\"#{study.uuid}\""
      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(1)
      expect(json['data'][0]['attributes']['uuid']).to eq(study.uuid)
    end
  end

  context 'with a study' do
    let(:resource_model) { create(:study) }

    it 'sends an individual study' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('studies')
    end
  end
end
