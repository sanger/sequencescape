# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

RSpec.describe Api::V2::QcAssaysController, :qc_result, with: :api_v2 do
  let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }
  let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }
  let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:receptacle).uuid) }
  let(:asset_invalid) { attributes_for(:qc_result) }
  let(:base_endpoint) { '/api/v2/qc_assays' }

  it_behaves_like 'ApiKeyAuthenticatable'

  it 'is true' do
    expect(true).to be_truthy
  end

  it 'creates a new qc assay' do
    params = { data: { attributes: { qc_results: [asset_1, asset_2, asset_3], lot_number: 'LN1234567' } } }
    api_post base_endpoint, params
    expect(QcResult.count).to eq(3)
    expect(QcAssay.count).to eq(1)
    expect(response).to have_http_status(:created)
    json = ActiveSupport::JSON.decode(response.body)['data']['attributes']
    expect(json['lot_number']).to eq('LN1234567')
    expect(json['qc_results'].length).to eq(3)
  end

  it 'returns an error if someone tries to create an invalid qc assay' do
    expect do
      api_post base_endpoint,
               {
                 data: {
                   attributes: {
                     qc_results: [asset_1, asset_2, asset_3, asset_invalid],
                     lot_number: 'LN1234567'
                   }
                 }
               }
    end.not_to change(QcAssay, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    json = ActiveSupport::JSON.decode(response.body)
    expect(json['errors'].length).to eq(1)
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:qc_assay) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
