# frozen_string_literal: true

require 'rails_helper'

describe 'Plates API', with: :api_v2 do
  context 'with multiple plates' do
    before do
      create_list(:plate, 5)
    end

    it 'sends a list of plates' do
      api_get '/api/v2/plates'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a plate' do
    let(:resource_model) { create :plate }
    let!(:resource_model_2) { create :plate }

    it 'sends an individual plate' do
      api_get "/api/v2/plates/#{resource_model.id}"
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('plates')
    end

    it 'filters by barcode' do
      api_get "/api/v2/plates?filter[barcode]=#{resource_model.ean13_barcode}"
      expect(response).to have_http_status(:success), response.body
      expect(json['data'].length).to eq(1)
    end

    it 'filtering by human barcode' do
      api_get "/api/v2/plates?filter[barcode]=#{resource_model.human_barcode}"
      expect(response).to have_http_status(:success), response.body
      expect(json['data'].length).to eq(1)
    end

    # By default jsonapi_resource has two bugs which affect polymorphic relationships
    # 1) It uses the default inheritnce_column `type` rather than the defined one
    # 2) It directly uses the type field, rather than mapping it to a resource
    # These tests validate both behaviours, as corrected in the monkey patch in
    # config/initializers/patch_json_api_resource.rb
    context 'with mixed ancestors' do
      before do
        resource_model.parents << create(:plate) << create(:multiplexed_library_tube)
      end

      it 'handles polymorphic relationships properly' do
        api_get "/api/v2/plates/#{resource_model.id}/parents"
        expect(response).to have_http_status(:success), response.body
        expect(json['data'].length).to eq(2)
        types = json['data'].map { |anc| anc['type'] }
        expect(types).to include('plates')
        expect(types).to include('tubes')
      end

      it 'handles polymorphic relationships properly' do
        api_get "/api/v2/plates/#{resource_model.id}/relationships/parents"
        expect(response).to have_http_status(:success), response.body
        expect(json['data'].length).to eq(2)
        types = json['data'].map { |anc| anc['type'] }
        expect(types).to include('plates')
        expect(types).to include('tubes')
      end
    end
  end
end
