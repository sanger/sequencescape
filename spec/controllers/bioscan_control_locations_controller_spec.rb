# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BioscanControlLocationsController, type: :controller do
  describe 'POST #create' do
    # Plate with samples and controls
    let!(:plate) do
      plate = create(:plate, purpose:)
      aliquots = (samples + controls).map { |sample| create(:aliquot, sample:) }
      aliquots.each.with_index(1).map do |aliquot, index|
        create(:well, plate: plate, aliquots: [aliquot],
                      map_id: to_horizontal(index))
      end
      plate.reload # Ensure wells are loaded
    end

    let(:purpose) do
      create(:purpose, name: described_class::BIOSCAN_PLATE_PURPOSE)
    end
    let(:barcode) { plate.human_barcode }
    let(:sample_count) { 20 }
    let(:samples) { create_list(:sample, sample_count) }
    let(:controls) do
      [
        create(:sample, control: true,
                        control_type: described_class::PCR_NEGATIVE),
        create(:sample, control: true,
                        control_type: described_class::PCR_POSITIVE)
      ]
    end

    let(:user) { 'user1' }
    let(:robot) { 'robot1' }

    # Helper to convert vertical index to horizontal index for 96-well plate.
    # @param index [Integer] one-based vertical index
    # @return [Integer] one-based horizontal index
    def to_horizontal(index)
      Map::Coordinate.vertical_to_horizontal(index, 96)
    end

    # Helper to get location at given index in column order for 96-well plate.
    # @param index [Integer] one-based index
    # @return [String] well description (e.g., "A1")
    def location_at(index)
      # 96-well plate with 8 rows
      Map::Coordinate.vertical_plate_position_to_description(index, 96)
    end

    context 'with valid plate and controls' do
      let(:expected) do
        # Assumes that controls are placed after samples
        {
          'barcode' => barcode,
          'negative_control' => location_at(sample_count + 1),
          'positive_control' => location_at(sample_count + 2)
        }
      end

      it 'returns locations' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when required params are missing' do
      let(:expected) do
        { 'errors' => [described_class::MISSING_PARAMS] }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user: } # missing robot
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when plate is missing' do
      let(:barcode) { 'NO_PLATE_DATA' }
      let(:expected) do
        {
          'errors' => [format(described_class::NO_PLATE_DATA, barcode:)]
        }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when plate purpose is incorrect' do
      let(:purpose) { create(:purpose, name: 'INCORRECT_PURPOSE') }
      let(:expected) do
        {
          'errors' => [format(
            described_class::INCORRECT_PURPOSE,
            purpose_name: purpose.name, barcode: barcode
          )]
        }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when plate has no samples' do
      let(:samples) { [] }
      let(:controls) { [] }
      let(:expected) do
        {
          'errors' => [format(described_class::NO_SAMPLES, barcode:)]
        }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when multiple controls are present' do
      let(:controls) do
        [
          # Two positive controls
          create(:sample, control: true,
                          control_type: described_class::PCR_POSITIVE),
          create(:sample, control: true,
                          control_type: described_class::PCR_POSITIVE),
          create(:sample, control: true,
                          control_type: described_class::PCR_NEGATIVE)
        ]
      end
      let(:expected) do
        {
          'errors' => [format(described_class::INCORRECT_CONTROLS, barcode:)]
        }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end

    context 'when controls are missing' do
      let(:controls) do
        [
          create(:sample, control: true,
                          control_type: described_class::PCR_POSITIVE)
          # Omitting negative control
        ]
      end
      let(:expected) do
        {
          'errors' => [format(described_class::MISSING_CONTROLS, barcode:)]
        }
      end

      it 'returns error' do # rubocop:disable RSpec/MultipleExpectations
        post :create, params: { barcode:, user:, robot: }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq(expected)
      end
    end
  end
end
