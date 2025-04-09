# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PlatesController, type: :request do
  describe 'POST /api/v2/plates/:id/register_stock_for_plate' do
    let(:plate) { instance_double(Plate, id: '123', wells: wells) }
    let(:wells) { instance_double('Wells', with_contents: [well1, well2]) }
    let(:well1) { instance_double(Well) }
    let(:well2) { instance_double(Well) }

    before do
      allow(well1).to receive(:register_stock!)
      allow(well2).to receive(:register_stock!)
    end

    context 'when the plate exists' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(plate)
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end

      it 'return success message' do
        expect(response.parsed_body['message']).to eq('Stock successfully registered for plate wells')
      end
    end

    context 'when the plate does not exist' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(nil)
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns a not found error' do
        expect(response.parsed_body['error']).to eq('Plate not found')
      end
    end

    context 'when an error occurs during registration' do
      before do
        allow(Plate).to receive(:find_by).with(id: '123').and_return(plate)
        allow(well1).to receive(:register_stock!).and_raise(StandardError.new('Some error'))
        post '/api/v2/plates/123/register_stock_for_plate'
      end

      it 'returns an error message' do
        expect(response.parsed_body['error']).to match(/Stock registration failed/)
      end
    end
  end
end
