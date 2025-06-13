# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NpgActions::AssetsController, type: :request do
  let(:user) { create(:user, password: 'password') }

  let(:lane) { create(:lane_with_stock_plate, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1) }
  let(:study) { create(:study) }
  let(:pipeline) { create(:sequencing_pipeline) }
  let(:batch) { create(:sequencing_batch, state: 'started', qc_state: 'qc_manual') }
  let(:valid_seq_request) do
    create(
      :sequencing_request_with_assets,
      batch: batch,
      request_type: batch.pipeline.request_types.first,
      study: study,
      target_asset: lane,
      state: 'passed'
    )
  end
  let(:cancelled_seq_request) do
    create(
      :sequencing_request_with_assets,
      batch: batch,
      request_type: batch.pipeline.request_types.first,
      study: study,
      target_asset: lane,
      state: 'cancelled'
    )
  end
  let(:failed_seq_request) do
    create(
      :sequencing_request_with_assets,
      batch: batch,
      request_type: batch.pipeline.request_types.first,
      study: study,
      target_asset: lane,
      state: 'failed'
    )
  end

  before { post '/login', params: { login: user.login, password: 'password' } }

  shared_examples 'a passed state change' do
    it 'renders and creates events', :aggregate_failures do
      # Response
      expect(response).to have_http_status(:ok)
      expect(response).to render_template :'assets/show'
      expect(response.body).to match(expected_response_content)

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
    it 'renders and creates events', :aggregate_failures do
      # Response
      expect(response).to render_template :'assets/show'
      expect(response.body).to match(expected_response_content)

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
    let(:expected_response_content) do
      Regexp.new(
        [
          '^(<asset api_version="0\.6">)(\n.*)*(<id>',
          lane.id.to_s,
          '<\/id>)\n.*(<type>Lane<\/type>)',
          '(\n.*<name>NPG_Action_Lane_Test<\/name>)',
          '(\n.*<public_name/>)',
          '(\n.*<qc_state>passed<\/qc_state>)',
          '(\n.*<sample_id\/>)',
          '(\n.*<children>)',
          '(\n.*</children>)',
          '(\n.*<parents>)',
          '(\n.*<id>',
          lane.parents.first.id,
          '<\/id>)',
          '(\n.*<\/parents>)',
          '(\n.*<requests>)',
          '(\n.*<\/requests>)',
          '(\n.*<\/asset>)$'
        ].join,
        Regexp::MULTILINE
      )
    end

    context 'with valid parameters' do
      before do
        valid_seq_request
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it_behaves_like 'a passed state change'
    end

    context 'with no valid requests' do
      before do
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            [
              '<error><message>',
              "Unable to identify a suitable single active request for Asset: #{lane.id}",
              '</message></error>'
            ].join,
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:not_found)
        expect(response.body).to match(regexp)
      end
    end

    context 'with a single cancelled request' do
      before do
        cancelled_seq_request
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            [
              '<error><message>',
              "Unable to identify a suitable single active request for Asset: #{lane.id}",
              '</message></error>'
            ].join,
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:not_found)
        expect(response.body).to match(regexp)
      end
    end

    context 'with both an active and an additional cancelled request' do
      before do
        valid_seq_request
        cancelled_seq_request
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it 'renders and creates events', :aggregate_failures do
        # This is the same as the passed state change shared test with a different batch state
        # This is because the cancelled requests arent filtered on the all_requests_qced? batch.rb method
        # which prevents it being released.
        # We don't know if this behaviour is desired, but I checked the data and the use case of
        # only a subset of the requests in a batch being cancelled does not seem to happen. See Y24-174.

        # Response
        expect(response).to have_http_status(:ok)
        expect(response).to render_template :'assets/show'
        expect(response.body).to match(expected_response_content)

        # Lane QC event
        expect(lane.events.last).to be_a Event::AssetSetQcStateEvent
        expect(lane.events.last.message).to eq('qc passed ok')

        # State event
        expect(Event.last).to be_a Event
        expect(Event.last.created_by).to eq('npg')
        expect(Event.last.message).to eq('Passed manual qc')

        # Batch state
        expect(batch.reload.state).to eq('started')

        # Broadcast sequencing completed event
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane)).to be_a BroadcastEvent::SequencingComplete
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane).properties[:result]).to eq('passed')
      end
    end

    context 'with two active requests' do
      before do
        valid_seq_request
        failed_seq_request
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            [
              '<error><message>',
              "Unable to identify a suitable single active request for Asset: #{lane.id}",
              '</message></error>'
            ].join,
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:not_found)
        expect(response.body).to match(regexp)
      end
    end

    context 'with an unrecognised lane' do
      let(:invalid_lane_id) { 999_999_999 }

      before do
        post "/npg_actions/assets/#{invalid_lane_id}/pass_qc_state",
             params: {
               asset_id: invalid_lane_id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            ['<error><message>', "Couldn't find Lane with 'id'=#{invalid_lane_id}", '.*</message></error>'].join,
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:not_found)
        expect(response.body).to match(regexp)
      end
    end

    context 'when changing qc state on an asset after NPG did the same action before' do
      # create a pass event for the lane source request
      let(:lane_receptacle) { Labware.find_by!(name: 'NPG_Action_Lane_Test').receptacle }
      let(:lane_source_request) { lane_receptacle.source_request }
      let(:prev_event) { create(:event, family: 'pass', created_by: 'npg', eventful: lane_source_request) }

      before do
        lane
        valid_seq_request
        prev_event
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'qc passed ok'
               }
             }
        lane.reload
      end

      it 'renders and but does not recreate the events', :aggregate_failures do
        # Response
        expect(response).to have_http_status(:ok)
        expect(response).to render_template :'assets/show'
        expect(response.body).to match(expected_response_content)

        # Lane QC event
        expect(lane.events.last).to be_nil
      end
    end

    context 'when posting invalid XML to change qc state on an asset. NPG did the same action before' do
      # create a pass event for the lane source request
      let(:lane_receptacle) { Labware.find_by!(name: 'NPG_Action_Lane_Test').receptacle }
      let(:lane_source_request) { lane_receptacle.source_request }
      let(:prev_event) { create(:event, family: 'pass', created_by: 'npg', eventful: lane_source_request) }

      before do
        lane
        valid_seq_request
        prev_event
        post "/npg_actions/assets/#{lane.id}/pass_qc_state",
             params: {
               asset_id: lane.id,
               unknown_attribute: {
                 qc_information: {
                   message: 'qc passed ok'
                 }
               }
             }
        lane.reload
      end

      it 'renders the exception page' do
        regexp =
          Regexp.new(
            ['<error><message>', 'param is missing or the value is empty: qc_information', '</message></error>'].join,
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to match(regexp)
      end
    end
  end

  describe '#fail' do
    let(:expected_response_content) do
      Regexp.new(
        [
          '^(<asset api_version="0\.6">)(\n.*)*(<id>',
          lane.id.to_s,
          '<\/id>)\n.*(<type>Lane<\/type>)',
          '(\n.*<name>NPG_Action_Lane_Test<\/name>)',
          '(\n.*<public_name/>)',
          '(\n.*<qc_state>failed<\/qc_state>)',
          '(\n.*<sample_id\/>)',
          '(\n.*<children>)',
          '(\n.*</children>)',
          '(\n.*<parents>)',
          '(\n.*<id>',
          lane.parents.first.id,
          '<\/id>)',
          '(\n.*<\/parents>)',
          '(\n.*<requests>)',
          '(\n.*<\/requests>)',
          '(\n.*<\/asset>)$'
        ].join,
        Regexp::MULTILINE
      )
    end

    context 'with valid parameters' do
      before do
        failed_seq_request
        post "/npg_actions/assets/#{lane.id}/fail_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'failed qc'
               }
             }
      end

      it_behaves_like 'a failed state change'
    end

    context 'with both a valid and an additional cancelled request' do
      before do
        failed_seq_request
        cancelled_seq_request
        post "/npg_actions/assets/#{lane.id}/fail_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'failed qc'
               }
             }
      end

      it 'renders and creates events', :aggregate_failures do
        # This is the same as the failed state change shared test with a different batch state
        # This is because the cancelled requests arent filtered on the all_requests_qced? batch.rb method
        # which prevents it being released.
        # We don't know if this behaviour is desired, but I checked the data and the use case of
        # only a subset of the requests in a batch being cancelled does not seem to happen. See Y24-174.

        # Response
        expect(response).to render_template :'assets/show'
        expect(response.body).to match(expected_response_content)

        # Lane QC event
        expect(lane.events.last).to be_a Event::AssetSetQcStateEvent
        expect(lane.events.last.message).to eq('failed qc')

        # State event
        expect(Event.last).to be_a Event
        expect(Event.last.created_by).to eq('npg')
        expect(Event.last.message).to eq('Failed manual qc')

        # Batch state
        expect(batch.reload.state).to eq('started')

        # Broadcast sequencing completed event
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane)).to be_a BroadcastEvent::SequencingComplete
        expect(BroadcastEvent::SequencingComplete.find_by(seed: lane).properties[:result]).to eq('failed')
      end
    end

    context 'when changing qc state on an asset when NPG did a different action before' do
      # create a pass event for the lane source request
      let(:lane_receptacle) { Labware.find_by!(name: 'NPG_Action_Lane_Test').receptacle }
      let(:lane_source_request) { lane_receptacle.source_request }
      let(:prev_event) { create(:event, family: 'pass', created_by: 'npg', eventful: lane_source_request) }

      before do
        lane
        failed_seq_request
        prev_event
        post "/npg_actions/assets/#{lane.id}/fail_qc_state",
             params: {
               asset_id: lane.id,
               qc_information: {
                 message: 'failed qc'
               }
             }
      end

      it 'returns a warning' do
        regexp =
          Regexp.new(
            "<error><message>The request on this lane has already been completed with qc state: 'pass'. " \
              "Unable to set it to new qc state: 'fail'.</message></error>",
            Regexp::MULTILINE
          )
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to match(regexp)
      end
    end
  end
end
