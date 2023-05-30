# frozen_string_literal: true

require 'rails_helper'

describe 'TagLayoutTemplates API', with: :api_v2 do
  context 'with multiple TagLayoutTemplates' do
    before { create_list(:tag_layout_template, 5) }

    it 'sends a list of tag_layout_templates' do
      api_get '/api/v2/tag_layout_templates'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a TagLayoutTemplate' do
    let(:resource_model) { create :tag_layout_template }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'tag_layout_templates',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual TagLayoutTemplate' do
      api_get "/api/v2/tag_layout_templates/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tag_layout_templates')
    end

    # Remove if immutable
    it 'allows update of a TagLayoutTemplate' do
      api_patch "/api/v2/tag_layout_templates/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tag_layout_templates')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
