# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'WorkOrders', type: :feature, aker: true do

  let!(:work_orders) { create_list(:aker_work_order_with_samples, 5) }
  let!(:work_order) { work_orders.first }
  let(:get_url) { "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}" }
  let(:request) { RestClient::Request.new(method: :get, url: get_url) }
  let(:work_order_json) do
    File.read(File.join('spec', 'data', 'aker', 'work_order.json'))
  end

  scenario 'view all work orders' do
    visit aker_work_orders_path
    expect(find('.work-orders')).to have_css('.work-order', count: 5)
  end

  context 'existing work order' do

    context 'active' do

      before(:each) do
        allow(RestClient::Request).to receive(:execute).with(method: :get, url: get_url, proxy: nil, headers: { content_type: :json, Accept: :json }).and_return(RestClient::Response.create(work_order_json, Net::HTTPResponse.new('1.1',200,''), request))
      end

      scenario 'view a work order' do
        visit aker_work_order_path(work_order)
        expect(page).to have_content("Work Orders")
        json = JSON.parse(work_order_json)['work_order']
        within('.work-order') do
          expect(page).to have_content(json['product_name'])
          expect(page).to have_content(json['product_version'])
          expect(page).to have_content(json['product_uuid'])
          expect(page).to have_content(json['proposal_id'])
          expect(page).to have_content(json['proposal_name'])
          expect(page).to have_content(json['cost_code'])
          expect(page).to have_content(json['comment'])
          expect(page).to have_content(json['desired_date'])
          expect(page).to have_content(json['status'])
          expect(page).to have_link("Complete")
          expect(page).to have_link("Cancel")
          expect(page).to have_css('.sample', count: work_order.samples.count)
        end
      end

      scenario 'complete' do
        visit aker_work_orders_path
        within("#aker_work_order_#{work_order.id}") do
          click_link "Show"
        end
        click_link "Complete"
        expect(page).to have content("Work Order successfully completed")
      end

      scenario 'complete new or updated materials'

      scenario 'cancel'
      end
    end

    context 'completed or cancelled' do
      scenario 'view' do
        visit aker_work_order_path(work_order)
        expect(page).to_not have_link("Complete")
        expect(page).to_not have_link("Cancel")
      end
    end

end
