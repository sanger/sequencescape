# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/requests'

RSpec.describe Api::V2::PlatesController, type: :request do
  describe 'POST /api/v2/plates/:id/register_stock_for_plate' do
    let(:plate) { create(:plate, well_count: 96) }
    let(:wells) { plate.wells }
    let(:well1) { wells[0] }
    let(:well2) { wells[1] }

    before do
      # Add content (aliquots) to only the first two wells
      plate.wells[0].aliquots << create(:aliquot, sample: create(:sample), receptacle: plate.wells[0])
      plate.wells[1].aliquots << create(:aliquot, sample: create(:sample), receptacle: plate.wells[1])
    end

    context 'when the plate exists' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(plate)
        allow(well1).to receive(:register_stock!)
        allow(well2).to receive(:register_stock!)
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        expect(response.parsed_body['message']).to eq('Stock successfully registered for plate wells')
      end
    end

    context 'when the plate does not exist' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(nil)
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns a 404 Not Found status' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a not found error' do
        expect(response.parsed_body['error']).to eq('Plate not found')
      end
    end

    context 'when an error occurs during registration' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(plate)
        allow(plate).to receive(:wells).and_return(wells)
        allow(wells).to receive(:with_contents).and_return([well1])
        allow(well1).to receive(:register_stock!).and_raise(StandardError.new('Stock registration failed'))
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns a 422 Unprocessable Entity status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error message' do
        expect(response.parsed_body['error']).to match(/Stock registration failed/)
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:plate) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
