# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::QcResultsController, type: :request, qc_result: true do
  let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
  let(:asset_invalid) { attributes_for(:qc_result) }

  it 'creates some new qc results' do
    params = { data: { attributes: [asset_1, asset_2, asset_3] } }
    expect do
      post api_v2_qc_results_path, params: params
    end.to change(QcResult, :count).by(3)
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
      post api_v2_qc_results_path, params: { data: { attributes: [asset_1, asset_2, asset_3, asset_invalid] } }
    end.to_not change(QcResult, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    json = ActiveSupport::JSON.decode(response.body)
    expect(json.keys.length).to eq(1)
  end
end
