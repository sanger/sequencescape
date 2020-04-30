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

    context 'when providing a payload for creating a plate' do
      let(:purpose) { create(:plate_purpose) }
      let(:study) { create(:study) }
      let!(:sample) { create(:sample) }
      let(:wells_content) do
        {
          'A01': { 'phenotype': 'A phenotype', 'study_uuid': study.uuid },
          'B01': { 'sample_uuid': sample.uuid }
        }
      end
      let(:barcode) { '0000000001' }
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              "barcode": barcode,
              'plate_purpose_uuid' => purpose.uuid,
              'wells_content' => wells_content
            }
          }
        }
      end

      context 'when payload is valid' do
        it 'creates a new plate' do
          expect do
            api_post '/api/v2/plates', payload
          end.to(change(Plate, :count).by(1).and(
            change(Sample, :count).by(1)
          ).and(
            change(Aliquot, :count).by(2)
          ))
          expect(response).to have_http_status(:created)
        end

        context 'with the created plate' do
          let(:request) { api_post '/api/v2/plates', payload }
          let(:plate_id) do
            request
            JSON.parse(response.body)['data']['id']
          end
          let(:plate) { ::Plate.find(plate_id) }

          it 'has defined the plate purpose' do
            expect(plate.plate_purpose).to eq(purpose)
          end

          it 'has the defined study' do
            expect(plate.studies).to eq([study])
          end

          it 'has a barcode' do
            expect(plate.primary_barcode).not_to be_nil
          end

          it 'creates the new plate with the barcode specified' do
            expect(plate.barcodes.map(&:barcode)).to include(barcode)
          end
        end

        context 'when there is an exception during plate creation' do
          before do
            allow(::Sample).to receive(:with_uuid).with(sample.uuid).and_raise('BOOM!!')
          end

          it 'does not create any plates' do
            expect do
              api_post '/api/v2/plates', payload
            end.not_to change(Plate, :count)
          end

          it 'does not create any samples' do
            expect do
              api_post '/api/v2/plates', payload
            end.not_to change(Sample, :count)
          end

          it 'does not create any aliquots' do
            expect do
              api_post '/api/v2/plates', payload
            end.not_to change(Aliquot, :count)
          end
        end
      end

      context 'when payload is not valid' do
        let(:payload) do
          {
            'data' => {
              'type' => 'plates',
              'attributes' => {
                'barcode' => barcode,
                'plate_purpose_uuid' => nil,
                'study_uuid' => study.uuid,
                'wells_content' => wells_content
              }
            }
          }
        end

        it 'does not create a new plate' do
          expect do
            api_post '/api/v2/plates', payload
          end.not_to(change(Plate, :count))
        end

        it 'does not create a new sample' do
          expect do
            api_post '/api/v2/plates', payload
          end.not_to(change(Sample, :count))
        end

        it 'returns an error code' do
          api_post '/api/v2/plates', payload
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns an error message' do
          api_post '/api/v2/plates', payload
          msg = JSON.parse(response.body)['errors'][0]['msg']
          expect(msg).to eq("Plate purpose can't be blank")
        end
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
