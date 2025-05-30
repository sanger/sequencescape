# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Barcode Printers API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/barcode_printers' }

  it_behaves_like 'ApiKeyAuthenticatable'

  describe '#get all Barcode Printers' do
    before { create_list(:barcode_printer, 5) }

    it 'returns the list of Barcode Printers' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  describe '#get a specific Barcode Printer' do
    let(:resource_model) { create(:barcode_printer) }

    it 'returns the template' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('barcode_printers')
      expect(json.dig('data', 'attributes', 'uuid')).to eq(resource_model.uuid)
      expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
      expect(json.dig('data', 'attributes', 'print_service')).to eq(resource_model.print_service)
      expect(json.dig('data', 'attributes', 'barcode_type')).to eq(resource_model.barcode_printer_type.name)
    end
  end

  describe '#patch a specific Barcode Printer' do
    let(:resource_model) { create(:barcode_printer) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'barcode_printers',
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

  describe '#post a new Barcode Printer' do
    let(:payload) { { 'data' => { 'type' => 'barcode_printers', 'attributes' => { 'name' => 'New Name' } } } }

    it 'finds no routes for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
