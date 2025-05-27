# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'TagGroups API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tag_groups' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple TagGroups' do
    before do
      create_list(:tag_group, 5)

      # Invisible tag groups should be hidden
      create_list(:tag_group, 2, visible: false)
    end

    it 'sends a list of tag_groups' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters

    it 'filters tag_groups by name' do
      api_get "#{base_endpoint}?filter[name]=#{TagGroup.first.name}"
      expect(response).to have_http_status(:success)

      # check to make sure the right tag group is returned
      expect(json['data'].length).to eq(1)
      expect(json['data'][0]['attributes']['name']).to eq(TagGroup.first.name)
    end
  end

  context 'with a TagGroup' do
    let(:resource_model) { create(:tag_group) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'tag_groups',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual TagGroup' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tag_groups')
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:tag_group) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
