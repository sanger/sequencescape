# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlatesController, type: :request do
  describe 'POST /api/v2/plates/:id/register_stock_for_plate' do
    let(:plate) { instance_double(Plate, id: '123', wells: wells) }
    let(:wells) { double('wells', with_contents: [well1, well2]) }
    let(:well1) { instance_double('Well') }
    let(:well2) { instance_double('Well') }

    before do
      allow(well1).to receive(:register_stock!)
      allow(well2).to receive(:register_stock!)
    end

    context 'when the plate exists' do
      before { allow(Plate).to receive(:find_by).with(id: '123').and_return(plate) }

      it 'registers stock and returns a success message' do
        post '/api/v2/plates/123/register_stock_for_plate'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Stock successfully registered for plate wells')
      end
    end

    context 'when the plate does not exist' do
      before { allow(Plate).to receive(:find_by).with(id: '123').and_return(nil) }

      it 'returns a not found error' do
        post '/api/v2/plates/123/register_stock_for_plate'

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Plate not found')
      end
    end

    context 'when an error occurs during registration' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(plate)
        allow(well1).to receive(:register_stock!).and_raise(StandardError.new('Some error'))
      end

      it 'returns an error message' do
        post '/api/v2/plates/123/register_stock_for_plate'

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to match(/Stock registration failed: Some error/)
      end
    end
  end
end
