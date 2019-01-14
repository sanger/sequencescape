# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::QcAssaysController, type: :request, qc_result: true do
  let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_invalid) { attributes_for(:qc_result) }

  it 'should be true' do
    expect(true).to be_truthy
  end

  it 'creates a new qc assay' do
    params = { data: { attributes: { qc_results: [asset_1, asset_2, asset_3], lot_number: 'LN1234567' } } }
    post api_v2_qc_assays_path, params: params
    expect(QcResult.count).to eq(3)
    expect(QcAssay.count).to eq(1)
    expect(response).to have_http_status(:created)
    json = ActiveSupport::JSON.decode(response.body)['data']['attributes']
    expect(json['lot_number']).to eq('LN1234567')
    expect(json['qc_results'].length).to eq(3)
  end

  it 'returns an error if someone tries to create an invalid qc assay' do
    expect do
      post api_v2_qc_assays_path, params: { data: { attributes: { qc_results: [asset_1, asset_2, asset_3, asset_invalid], lot_number: 'LN1234567' } } }
    end.to_not change(QcAssay, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    json = ActiveSupport::JSON.decode(response.body)
    expect(json['errors'].length).to eq(1)
  end
end
