# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

RSpec.describe Api::V2::QcResultsController, :qc_result, with: :api_v2 do
  let(:asset_invalid) { attributes_for(:qc_result) }
  let(:base_endpoint) { '/api/v2/qc_results' }

  it_behaves_like 'ApiKeyAuthenticatable'

  describe 'by uuid' do
    let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }
    let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }
    let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }

    it 'creates some new qc results' do
      params = { data: { attributes: [asset_1, asset_2, asset_3] } }
      expect { api_post base_endpoint, params }.to change(QcResult, :count).by(3)
      expect(response).to have_http_status(:created)

      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(3)
      qc_result = json['data'].first['attributes']
      expect(qc_result['key']).to eq(asset_1[:key])
      expect(qc_result['value']).to eq(asset_1[:value])
      expect(qc_result['units']).to eq(asset_1[:units])
      expect(qc_result['cv']).to eq(asset_1[:cv])
      expect(qc_result['assay_type']).to eq(asset_1[:assay_type])
      expect(qc_result['assay_version']).to eq(asset_1[:assay_version])
    end

    it 'returns an error if somebody tries to create an invalid qc result' do
      expect do
        api_post base_endpoint, { data: { attributes: [asset_1, asset_2, asset_3, asset_invalid] } }
      end.not_to change(QcResult, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      json = ActiveSupport::JSON.decode(response.body)
      expect(json.keys.length).to eq(1)
    end
  end

  describe 'by barcode' do
    let(:asset_1) { attributes_for(:qc_result).merge(barcode: create(:tube).barcodes.first.barcode) }
    let(:asset_2) { attributes_for(:qc_result).merge(barcode: create(:tube).barcodes.first.barcode) }
    let(:asset_3) { attributes_for(:qc_result).merge(barcode: create(:tube).barcodes.first.barcode) }

    it 'creates some new qc results' do
      params = { data: { attributes: [asset_1, asset_2, asset_3] } }
      expect { api_post base_endpoint, params }.to change(QcResult, :count).by(3)
      expect(response).to have_http_status(:created)

      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(3)
      qc_result = json['data'].first['attributes']
      expect(qc_result['key']).to eq(asset_1[:key])
      expect(qc_result['value']).to eq(asset_1[:value])
      expect(qc_result['units']).to eq(asset_1[:units])
      expect(qc_result['cv']).to eq(asset_1[:cv])
      expect(qc_result['assay_type']).to eq(asset_1[:assay_type])
      expect(qc_result['assay_version']).to eq(asset_1[:assay_version])
    end

    it 'returns an error if somebody tries to create an invalid qc result' do
      expect do
        api_post base_endpoint, { data: { attributes: [asset_1, asset_2, asset_3, asset_invalid] } }
      end.not_to change(QcResult, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      json = ActiveSupport::JSON.decode(response.body)
      expect(json.keys.length).to eq(1)
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:qc_result) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
