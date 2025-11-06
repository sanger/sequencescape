# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'PlateTemplates API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/plate_templates' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple PlateTemplates' do
    before { create_list(:plate_template, 5) }

    it 'sends a list of plate_templates' do
      api_get base_endpoint

      puts response.body

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a PlateTemplate' do
    let(:resource_model) { create(:plate_template) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'plate_templates',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual PlateTemplate' do
      api_get "#{base_endpoint}/#{resource_model.id}"

      puts response.body

      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('plate_templates')
    end

    # Remove if immutable
    it 'allows update of a PlateTemplate' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload

      puts response.body

      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('plate_templates')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
