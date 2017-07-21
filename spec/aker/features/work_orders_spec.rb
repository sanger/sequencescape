# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'WorkOrders', type: :feature, aker: true do

  let!(:work_order) { create(:work_order_with_samples) }
  let(:url) { "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}" }
  let(:request) { RestClient::Request.new(method: :get, url: url) }
  let(:work_order_json) do
    file = File.read(File.join('spec', 'data', 'aker', 'work_order.json'))
    JSON.parse(file)
  end

  scenario 'view all work orders' do
    create_list(:work_order_with_samples, 5)
    visit aker_work_orders_path
    expect(find('.work-orders')).to have_css('.work-order', count: 6)
  end

  scenario 'view a work order' do
    allow(RestClient).to receive(:get).with(url).and_return(RestClient::Response.create(work_order_json, Net::HTTPResponse.new('1.1',200,''), request, Time.now))
    visit aker_work_order_path(work_order)
    expect(page).to have_content("Work Orders")
    json = work_order_json['work_order']
    within('.work-order') do
      expect(page).to have_content(json['product_name'])
      expect(page).to have_content(json['product_version'])
      expect(page).to have_content(json['product_uuid'])
      expect(page).to have_content(json['proposal_id'])
      expect(page).to have_content(json['proposal_name'])
      expect(page).to have_content(json['cost_code'])
      expect(page).to have_content(json['comment'])
      expect(page).to have_content(json['desired_date'])
      expect(page).to have_css('.sample', count: work_order.samples.count)
    end
  end

  scenario 'complete a work order'

  scenario 'complete a work order with new or updated materials'

  scenario 'cancel a work order'
end