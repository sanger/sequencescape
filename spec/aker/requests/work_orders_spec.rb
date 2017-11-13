# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aker::WorkOrdersController, type: :request, aker: true do

  let!(:work_order) { create(:aker_work_order) }
  let(:url) { "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}" }
  let(:request) { RestClient::Request.new(method: :post, url: url) }

  scenario 'complete a work order' do
    allow(RestClient::Request).to receive(:execute).with(
      verify_ssl: false,
      method: :post, url: "#{url}/complete", payload: {
          work_order: {work_order_id: work_order.aker_id, comment: "Complete it"}}.to_json, 
        headers: {content_type: :json}, proxy: nil).and_return(
          RestClient::Response.create({work_order: {id: work_order.aker_id, comment: "Complete it"}}.to_json, 
            Net::HTTPResponse.new('1.1',200,''), request))

    post complete_aker_work_order_path(work_order), params: {comment: "Complete it"}
    
    expect(response).to redirect_to(aker_work_order_path(work_order))
  end

  scenario 'cancel a work order' do
    allow(RestClient::Request).to receive(:execute).with(
      verify_ssl: false,
      method: :post, url: "#{url}/cancel", payload: {
      work_order: {work_order_id: work_order.aker_id, comment: "Cancel it"}}.to_json, 
      headers: {content_type: :json}, proxy: nil).and_return(RestClient::Response.create({
        work_order: {id: work_order.aker_id, comment: "Cancel it"}}.to_json, 
        Net::HTTPResponse.new('1.1',200,''), request))

    post cancel_aker_work_order_path(work_order), params: {comment: "Cancel it"}

    expect(response).to redirect_to(aker_work_order_path(work_order))
  end
end