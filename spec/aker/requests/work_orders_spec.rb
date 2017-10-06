# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aker::WorkOrdersController, type: :request, aker: true do

  let!(:work_order) { create(:aker_work_order) }
  let(:url) { "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}" }
  let(:request) { RestClient::Request.new(method: :post, url: url) }

  scenario 'complete a work order' do
    allow(RestClient).to receive(:post).with("#{url}/complete", {work_order: {id: work_order.aker_id, comment: "Complete it"}}, {content_type: :json}).and_return(RestClient::Response.create({work_order: {id: work_order.aker_id, comment: "Complete it"}}.to_json, Net::HTTPResponse.new('1.1',200,''), request))
    post complete_aker_work_order_path(work_order), params: {comment: "Complete it"}
    expect(response).to be_success
    expect(ActiveSupport::JSON.decode(response.body)['work_order']).to eq({'id' => work_order.aker_id, 'comment' => "Complete it"})
  end

  scenario 'cancel a work order' do
    allow(RestClient).to receive(:post).with("#{url}/cancel", {work_order: {id: work_order.aker_id, comment: "Cancel it"}}, {content_type: :json}).and_return(RestClient::Response.create({work_order: {id: work_order.aker_id, comment: "Cancel it"}}.to_json, Net::HTTPResponse.new('1.1',200,''), request))
    post cancel_aker_work_order_path(work_order), params: {comment: "Cancel it"}
    expect(response).to be_success
    expect(ActiveSupport::JSON.decode(response.body)['work_order']).to eq({'id' => work_order.aker_id, 'comment' => "Cancel it"})

  end
end