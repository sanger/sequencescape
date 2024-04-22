# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'PlatePicks' do
  let(:user) { create(:user, password: 'password') }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let(:plate) { create(:plate, well_count: 1) }
  let(:destination_plate) { create(:plate, well_count: 1) }
  let(:released_cherrypick_batch) do
    build(:cherrypick_batch,
          state: 'released',
          request_attributes: [{ asset: plate.wells[0], target_asset: destination_plate.wells.first, state: 'passed' }])
  end
  let(:released_other_batch) { build(:batch, state: 'released', request_attributes: [{ asset: plate.wells[0] }]) }
  let(:pending_cherrypick_batch) do
    build(:cherrypick_batch, state: 'pending', request_attributes: [{ asset: plate.wells[0] }])
  end

  # We exclude the pending batches here, as they don't have pick information.
  # Initially we still showed them, to improve visibility of pending work, but UAT feedback
  # was that this was confusing, and they'd prefer to hide them.
  let(:batch_ids) { [released_cherrypick_batch.id.to_s] }
  let(:plate_payload) do
    { 'id' => plate.id, 'barcode' => plate.machine_barcode, 'control' => false, 'batches' => batch_ids }
  end
  let(:found_plate) { { 'plate' => plate_payload } }
  let(:missing_plate) { '{"errors":"Could not find plate in Sequencescape"}' }
  let(:pick_name) { "#{released_cherrypick_batch.id}:#{destination_plate.human_barcode} 1 of 1" }
  let(:found_batch) do
    {
      'batch' => {
        'id' => released_cherrypick_batch.id.to_s,
        'picks' => [{ 'name' => pick_name, 'plates' => [plate_payload] }]
      }
    }
  end
  let(:not_suitable) { '{"errors":"Batch has no pick information"}' }
  let(:missing_batch) { '{"errors":"Could not find batch in Sequencescape"}' }

  before { post '/login', params: { login: user.login, password: 'password' } }

  describe 'GET show' do
    it 'returns the application', :aggregate_failures do
      get '/plate_picks'
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET plates/:barcode' do
    before do
      released_cherrypick_batch.save!
      pending_cherrypick_batch.save!
      released_other_batch.save!
    end

    it 'returns the plate', :aggregate_failures do
      get("/plate_picks/plates/#{plate.machine_barcode}", headers:)
      expect(response.media_type).to eq('application/json')
      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq(found_plate)
    end

    it 'returns 404 if the plate is missing', :aggregate_failures do
      get('/plate_picks/plates/not_a_barcode', headers:)
      expect(response.media_type).to eq('application/json')
      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq(missing_plate)
    end
  end

  describe 'GET batches/:id' do
    before do
      create(:robot_with_verification_behaviour)
      released_cherrypick_batch.save!
      pending_cherrypick_batch.save!
      released_other_batch.save!
    end

    it 'returns the batch', :aggregate_failures do
      get("/plate_picks/batches/#{released_cherrypick_batch.id}", headers:)
      expect(response.media_type).to eq('application/json')
      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq(found_batch)
    end

    it 'returns an error if the batch has no pick info', :aggregate_failures do
      get("/plate_picks/batches/#{pending_cherrypick_batch.id}", headers:)
      expect(response.media_type).to eq('application/json')
      expect(response).to have_http_status(:conflict)
      expect(response.body).to eq(not_suitable)
    end

    it 'returns 404 if the batch is missing', :aggregate_failures do
      get('/plate_picks/batches/not_a_barcode', headers:)
      expect(response.media_type).to eq('application/json')
      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq(missing_batch)
    end
  end
end
