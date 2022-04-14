# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NpgActions::AssetsController, type: :controller do
  let(:user) { create :user }

  before { session[:user] = user.id }

  let(:lane) { create :lane_with_stock_plate }
  let(:study) { create :study }
  let(:batch) { create :sequencing_batch, state: 'started' }
  let(:validSeqRequest) do
    create :sequencing_request_with_assets,
    batch: batch,
    request_type: batch.pipeline.request_types.first,
    study: study,
    target_asset: lane,
    state: 'passed'
  end
  let(:cancelledSeqRequest) do
    create :sequencing_request_with_assets,
    batch: batch,
    request_type: batch.pipeline.request_types.first,
    study: study,
    target_asset: lane,
    state: 'cancelled'
  end
  let(:failedSeqRequest) do
    create :sequencing_request_with_assets,
    batch: batch,
    request_type: batch.pipeline.request_types.first,
    study: study,
    target_asset: lane,
    state: 'failed'
  end

  shared_examples 'a passed state change' do
    it 'renders and creates events', aggregate_failures: true do
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

  shared_examples 'a failed state change' do
    it 'renders and creates events', aggregate_failures: true do
      expect(response).to render_template :'assets/show.xml.builder'

      # Lane QC event
      expect(lane.events.last).to be_a Event::AssetSetQcStateEvent
      expect(lane.events.last.message).to eq('failed qc')

      # State event
      expect(Event.last).to be_a Event
      expect(Event.last.created_by).to eq('npg')
      expect(Event.last.message).to eq('Failed manual qc')

      # Batch state
      expect(batch.reload.state).to eq('released')

      # Broadcast sequencing completed event
      expect(BroadcastEvent::SequencingComplete.find_by(seed: lane)).to be_a BroadcastEvent::SequencingComplete
      expect(BroadcastEvent::SequencingComplete.find_by(seed: lane).properties[:result]).to eq('failed')
    end
  end

  describe '#pass' do
    context 'with valid parameters' do
      before do
        validSeqRequest
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'qc passed ok'} }, session: { user: user.id }
      end

      it_behaves_like 'a passed state change'
    end

    context 'with no valid requests' do
      before do
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'qc passed ok'} }, session: { user: user.id }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            "<error><message>Unable to identify a suitable single active request for Asset: #{lane.id}</message></error>",
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(404)
        expect(response.body).to match(regexp)
      end
    end

    context 'with a single cancelled request' do
      before do
        cancelledSeqRequest
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'qc passed ok'} }, session: { user: user.id }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            "<error><message>Unable to identify a suitable single active request for Asset: #{lane.id}</message></error>",
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(404)
        expect(response.body).to match(regexp)
      end
    end

    context 'with both a valid and an additional cancelled request' do
      before do
        validSeqRequest
        cancelledSeqRequest
        post :pass, params: { asset_id: lane.id, qc_information: { message: 'qc passed ok'} }, session: { user: user.id }
      end

      it_behaves_like 'a passed state change'
    end
  end

  describe "#fail" do
    context 'with valid parameters' do
      before do
        failedSeqRequest
        post :fail, params: { asset_id: lane.id, qc_information: { message: 'failed qc'} }, session: { user: user.id }
      end

      it_behaves_like 'a failed state change'
    end

    context 'with both a valid and an additional cancelled request' do
      before do
        failedSeqRequest
        cancelledSeqRequest
        post :fail, params: { asset_id: lane.id, qc_information: { message: 'failed qc'} }, session: { user: user.id }
      end

      it_behaves_like 'a failed state change'
    end
  end
end

