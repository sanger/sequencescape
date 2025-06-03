# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Submission Templates API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/submission_templates' }

  it_behaves_like 'ApiKeyAuthenticatable'

  describe '#get all Submission Templates' do
    before { create_list(:submission_template, 5) }

    it 'returns the list of Submission Templates' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  describe '#get a specific Submission Template' do
    let(:resource_model) { create(:submission_template) }

    it 'returns the template' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('submission_templates')
      expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
    end
  end

  describe '#patch a specific Submission Template' do
    let(:resource_model) { create(:submission_template) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'submission_templates',
          'attributes' => {
            'name' => 'Updated Name'
          }
        }
      }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#post a new Submission Template' do
    let(:payload) { { 'data' => { 'type' => 'submission_templates', 'attributes' => { 'name' => 'New Name' } } } }

    it 'finds no routes for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
