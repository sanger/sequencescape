# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Bioscan::ExportPoolXpToTractionController, :bioscan, type: :request do
  let(:tube_state) { 'passed' }
  let(:tube_purpose_name) { 'LBSN-9216 Lib PCR Pool XP' }
  let(:requested_barcode) { tube.human_barcode }

  let(:tube_purpose) { create(:tube_purpose, name: tube_purpose_name) }
  let(:tube) { create(:multiplexed_library_tube, purpose: tube_purpose) }

  let(:params) do
    {
      data: {
        type: 'export_pool_xp_to_traction',
        attributes: {
          barcode: requested_barcode
        }
      }
    }.with_indifferent_access
  end

  before do
    create(:transfer_request, state: tube_state, target_asset: tube.receptacle)
    post api_v2_bioscan_export_pool_xp_to_traction_index_path, params:
  end

  context 'when the tube exists with the correct properties' do
    it 'responds with an OK status' do
      expect(response).to have_http_status(:ok)
    end

    it 'enqueues the ExportPoolXpToTractionJob' do
      expect(Delayed::Job.last.handler).to include('ExportPoolXpToTractionJob')
    end
  end

  context 'when the tube does not exist' do
    let(:requested_barcode) { 'DOES-NOT-EXIST' }

    it 'responds with an unprocessable entity status' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error message' do
      expect(response.body).to include("Tube with barcode '#{requested_barcode}' not found")
    end
  end

  context 'when the tube has the wrong purpose' do
    let(:tube_purpose_name) { 'WRONG-PURPOSE' }

    it 'responds with an unprocessable entity status' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error message' do
      expect(response.body).to include("Tube with barcode '#{requested_barcode}' is not a Pool XP tube")
    end
  end

  context 'when the tube is not in the passed state' do
    let(:tube_state) { 'failed' }

    it 'responds with an unprocessable entity status' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error message' do
      expect(response.body).to include("Tube with barcode '#{requested_barcode}' is not in the 'passed' state")
    end
  end
end
