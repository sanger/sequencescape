# frozen_string_literal: true

require 'rails_helper'

describe 'PrimerPanels API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/primer_panels' }

  context 'with multiple primer_panels' do
    before { create_list(:primer_panel, 5) }

    it 'sends a list of primer_panels' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a primer_panel' do
    let(:resource_model) { create :primer_panel }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'primer_panels',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual primer_panel' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('primer_panels')
    end

    # Remove if immutable
    it 'allows update of a primer_panel' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('primer_panels')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
