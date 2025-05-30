# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'TagLayoutTemplates API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tag_layout_templates' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple enabled TagLayoutTemplates' do
    before { create_list(:tag_layout_template, 5) }

    it 'responds with a success HTTP status code' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
    end

    it 'responds with all the TagLayoutTemplates' do
      api_get base_endpoint

      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a mix of enabled/disabled TagLayoutTemplates' do
    before do
      create_list(:tag_layout_template, 3, enabled: true)
      create_list(:tag_layout_template, 2, enabled: false)
    end

    it 'responds with a success HTTP status code' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
    end

    it 'responds with only the enabled TagLayoutTemplates as a default' do
      api_get base_endpoint

      expect(json['data'].length).to eq(3)
    end
  end

  context 'with a TagLayoutTemplate' do
    let(:resource_model) { create(:tag_layout_template) }

    describe '#get' do
      it 'responds with a success HTTP status code' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(response).to have_http_status(:success)
      end

      it 'responds with the correct data for the TagLayoutTemplate' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(json.dig('data', 'id')).to eq resource_model.id.to_s
        expect(json.dig('data', 'type')).to eq('tag_layout_templates')
        expect(json.dig('data', 'relationships', 'tag_group')).to be_present
        expect(json.dig('data', 'relationships', 'tag2_group')).to be_present
        expect(json.dig('data', 'attributes', 'uuid')).to eq resource_model.uuid
        expect(json.dig('data', 'attributes', 'name')).to eq resource_model.name
        expect(json.dig('data', 'attributes', 'direction')).to eq resource_model.direction
        expect(json.dig('data', 'attributes', 'walking_by')).to eq resource_model.walking_by
      end
    end

    describe '#patch' do
      let(:payload) do
        { 'data' => { 'id' => resource_model.id, 'type' => 'tag_layout_templates', 'attributes' => {} } }
      end

      it 'cannot find a route to the endpoint' do
        expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
          ActionController::RoutingError
        )
      end
    end
  end

  describe '#post' do
    let(:payload) { { 'data' => { 'type' => 'tag_layout_templates', 'attributes' => {} } } }

    it 'cannot find a route to the endpoint' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
