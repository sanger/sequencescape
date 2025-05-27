# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Transfer Templates API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/transfer_templates' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of TransferTemplates' do
    let!(:transfer_templates) { create_list(:transfer_template, 5) }

    describe '#get all TransferTemplates' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the full list of TransferTemplates' do
        expect(json['data'].length).to eq(5)
      end
    end

    describe '#get TransferTemplates by UUID' do
      let(:uuids) { transfer_templates.map(&:uuid).first(3) }

      before { api_get base_endpoint + "?filter[uuid]=#{uuids.join(',')}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns matching TransferTemplates matching UUIDs' do
        expect(json['data'].length).to eq(3)
      end
    end

    describe '#get TransferTemplate by ID' do
      let(:transfer_template) { transfer_templates.first }

      before { api_get "#{base_endpoint}/#{transfer_template.id}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the TransferTemplate' do
        expect(json.dig('data', 'id')).to eq(transfer_template.id.to_s)
        expect(json.dig('data', 'type')).to eq('transfer_templates')
        expect(json.dig('data', 'attributes', 'name')).to eq(transfer_template.name)
        expect(json.dig('data', 'attributes', 'uuid')).to eq(transfer_template.uuid)
      end
    end
  end

  describe '#patch a Transfer Template' do
    let(:resource_model) { create(:transfer_template) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'transfer_templates',
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

  describe '#post a new Transfer Template' do
    let(:payload) { { 'data' => { 'type' => 'transfer_templates', 'attributes' => { 'name' => 'New Name' } } } }

    it 'finds no routes for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:transfer_template) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
