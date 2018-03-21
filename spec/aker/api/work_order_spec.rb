require 'rails_helper'

RSpec.describe Api::V2::WorkOrdersController, type: :request, aker: true do
  let(:params) { { 'work_order' => build(:aker_work_order_json).with_indifferent_access } }

  it 'creates a new work order' do
    expect do
      post api_v2_aker_work_orders_path, params: params
    end.to change(Aker::WorkOrder, :count).by(1)
    expect(response).to have_http_status(:created)

    json = ActiveSupport::JSON.decode(response.body)
    expect(json).to eq(params)
  end

  it 'returns an error if somebody tries to create an invalid work order' do
    params['work_order'].delete('work_order_id')
    expect do
      post api_v2_aker_work_orders_path, params: params
    end.to_not change(Aker::WorkOrder, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    json = ActiveSupport::JSON.decode(response.body)
    expect(json['aker_id']).to_not be_empty
  end
end
