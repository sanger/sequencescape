# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NpgActions::AssetsController, type: :controller do
  let(:user) { create :user }

  before { session[:user] = user.id }

  let(:lane) { create :lane_with_stock_plate }
  let(:study) { create :study }
  let(:batch) { create :sequencing_batch, state: 'started' }
  let!(:request) do
    create :sequencing_request_with_assets,
    batch: batch,
    request_type: batch.pipeline.request_types.first,
    study: study,
    target_asset: lane
  end

  describe '#pass' do
    context 'with valid parameters' do
      before do
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'qc passed ok'} }, session: { user: user.id }
      end

      it 'renders the form and creates the correct events', aggregate_failures: true do
        expect(response).to render_template :'assets/show.xml.builder'

        # Lane QC event
        expect(lane.events.last).to be_a Event::AssetSetQcStateEvent
        expect(lane.events.last.message).to eq('qc passed ok')

        # State event
        expect(Event.last).to be_a Event
        expect(Event.last.created_by).to eq('npg')
        expect(Event.last.message).to eq('Passed manual qc')

        # Batch state
        expect(batch.reload.state).to eq('released')

        # Broadcast sequencing completed event
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane)).to be_a BroadcastEvent::SequencingComplete
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane).properties[:result]).to eq('passed')
      end
    end

    context 'with an additional cancelled request' do
      let!(:request2) do
        create :sequencing_request_with_assets,
        batch: batch,
        request_type: batch.pipeline.request_types.first,
        study: study,
        target_asset: lane,
        state: 'cancelled'
      end

      before do
        request2
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'test'} }, session: { user: user.id }
      end

      it 'renders the form' do
        expect(response).to render_template :'assets/show.xml.builder'
      end
    end
  end

  # describe "#fail" do
  #   it 'can be failed' do
  #     # event should be generated

  #     # batch state should be set
  #   end
  # end
end

