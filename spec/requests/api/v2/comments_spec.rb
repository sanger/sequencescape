# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Comments API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/comments' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple Comments' do
    before { create_list(:comment, 5) }

    it 'sends a list of comments' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a Comment' do
    let(:resource_model) { create(:comment) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'comments',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual Comment' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('comments')
    end

    # Remove if immutable
    it 'allows update of a Comment' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('comments')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end

  describe '#post' do
    let(:plate) { create(:plate) }
    let!(:request) { create(:well_request, asset: plate.wells.first) }

    let(:payload) do
      {
        'data' => {
          'type' => 'comments',
          'attributes' => {
            'title' => 'comment',
            'description' => 'This plate is pretty'
          },
          'relationships' => {
            'commentable' => {
              'data' => {
                'type' => 'labware',
                'id' => plate.id.to_s
              }
            }
          }
        }
      }
    end

    # Remove if immutable
    it 'allows creation of a Comment' do
      api_post base_endpoint, payload
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('comments')
      expect(json.dig('data', 'attributes', 'description')).to eq('This plate is pretty')
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:comment) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
