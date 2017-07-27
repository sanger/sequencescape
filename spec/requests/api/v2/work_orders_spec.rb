# frozen_string_literal: true

require 'rails_helper'

describe 'WorkOrders API', with: :api_v2 do
  context 'with multiple requests' do
    let(:our_request_type) { create :request_type }
    let(:other_request_type) { create :request_type }
    before do
      [
        { request_type: our_request_type, state: 'pending' },
        { request_type: our_request_type, state: 'pending' },
        { request_type: our_request_type, state: 'started' },
        { request_type: other_request_type, state: 'pending' },
        { request_type: other_request_type, state: 'started' }
      ].map do |options|
        create(:library_request, options)
      end
    end

    it 'sends a list of work_orders' do
      api_get '/api/v2/work-orders'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    it 'allows filtering of work_orders by state' do
      api_get '/api/v2/work-orders?filter[state]=pending'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(3)
    end

    it 'allows filtering of work_orders by order type' do
      api_get "/api/v2/work-orders?filter[order-type]=#{our_request_type.key}"
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(3)
    end

    it 'allows filtering of work_orders by order type and state' do
      api_get "/api/v2/work-orders?filter[order-type]=#{our_request_type.key}&filter[state]=pending"
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(2)
    end
  end

  context 'with relationships' do
    let(:study) { create :study }
    let(:well) { create :untagged_well }
    let(:sample) { well.samples.first }

    before do
      create :library_request, initial_study: study, asset: well, project: nil
    end

    let(:expected_includes) do
      # Note, we don't test the actual resource content here.
      [
        { 'type' => 'studies', 'id' => study.id.to_s },
        { 'type' => 'samples', 'id' => sample.id.to_s }
      ]
    end

    it 'can inline all necessary information' do
      api_get '/api/v2/work-orders?include=study,samples,project'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['included']).to include_json(expected_includes)
    end
  end

  context 'with a request' do
    let(:request) { create :library_request }

    it 'sends an individual work_order' do
      api_get "/api/v2/work-orders/#{request.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('work-orders')
    end

    let(:payload) do
      {
        'data' => {
          'id' => request.id,
          'type' => 'work-orders',
          'attributes' => {
            'state' => 'started',
            'at-risk' => true
          }
        }
      }
    end

    it 'allowd update of a work order' do
      api_patch "/api/v2/work-orders/#{request.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('work-orders')
      expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
