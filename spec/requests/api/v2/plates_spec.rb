# frozen_string_literal: true

require 'rails_helper'

describe 'Plates API', with: :api_v2, tags: :lighthouse do
  let(:params) do
  end

  describe '#create' do
    include BarcodeHelper

    before do
      mock_plate_barcode_service
    end

    let(:request) { api_post '/api/v2/plates', payload }
    let(:plate) do
      request
      uuid = JSON.parse(response.body).dig('data', 'attributes', 'uuid')
      Plate.with_uuid(uuid).first
    end

    shared_examples_for 'a successful plate creation' do
      it 'returns 201' do
        request
        expect(response).to have_http_status(:created)
      end

      it 'can create a plate' do
        expect { request }.to change(Plate, :count).by(1)
      end
    end

    context 'when providing a payload using default JSON API' do
      let(:purpose) { create :plate_purpose }
      let(:well) { create :well }
      let(:well2) { create :well }
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
            },
            relationships: {
              purpose: {
                data: { id: purpose.id.to_s, type: 'purposes' }
              },
              wells: {
                data: [
                  { type: 'wells', id: well.id }, { type: 'wells', id: well2.id }
                ]
              }
            }
          }
        }
      end

      it_behaves_like 'a successful plate creation'

      it 'creates the wells' do
        expect(plate.wells).to eq([well, well2])
      end
    end
  end

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

    context 'when the ancestor is a tube rack' do
      let(:purpose) do
        create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
      end
      let(:rack) { create :tube_rack }
      let(:plate_factory) { ::Heron::Factories::PlateFromRack.new(tube_rack: rack, plate_purpose: purpose) }
      let(:tubes) { create_list(:sample_tube, 2) }

      include BarcodeHelper

      before do
        mock_plate_barcode_service
        rack.racked_tubes << create(:racked_tube, tube: tubes[0], coordinate: 'A1')
        rack.racked_tubes << create(:racked_tube, tube: tubes[1], coordinate: 'B1')
      end

      it 'can find the plate' do
        plate_factory.save
        plate = plate_factory.plate
        barcode = plate.barcodes.first.barcode
        api_get "/api/v2/plates?filter[barcode=#{barcode}&include=purpose,parents"
        expect(response).to have_http_status(:success)
      end
    end

    # By default jsonapi_resource has two bugs which affect polymorphic relationships
    # 1) It uses the default inheritance_column `type` rather than the defined one
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

    context 'with comments on plates' do
      before do
        resource_model.comments.create(title: 'Test', description: 'We have some text', user: create(:user))
      end

      it 'returns the comment' do
        api_get "/api/v2/plates/#{resource_model.id}/comments"
        expect(response).to have_http_status(:success), response.body
        expect(json['data'].length).to eq(1)
        types = json['data'].map { |comment| comment['type'] }
        expect(types).to include('comments')
        expect(json['data'].first['attributes']['title']).to eq('Test')
      end
    end
  end
end
