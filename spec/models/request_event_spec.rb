# frozen_string_literal: true

require 'rails_helper'

describe RequestEvent do
  context 'Customer Requests' do
    let!(:request) { create(:customer_request, asset: create(:well), target_asset: create(:well)) }

    context 'creating requests' do
      it 'records a RequestEvent' do
        expect(described_class.count).to eq 1
      end

      it 'records a RequestEvent for each new Request' do
        expect(request.request_events.count).to eq 1
        expect(request.current_request_event.from_state).to be_nil
        expect(request.current_request_event.to_state).to eq 'pending'
        expect(request.current_request_event.event_name).to eq 'created'
        expect(request.current_request_event.current_to).to be_nil
      end
    end

    context 'changing request state to start' do
      before { request.start! }

      it 'records new state change RequestEvents for each request' do
        expect(described_class.count).to eq 2
      end

      it 'records a new state change RequestEvent from "pending"' do
        event = request.current_request_event
        expect(event.from_state).to eq 'pending'
      end

      it 'records a new state change RequestEvent to "started"' do
        event = request.current_request_event
        expect(event.to_state).to eq 'started'
      end

      it 'sets a current_to stamp on old events' do
        old_event = request.request_events.order(:id).first
        expect(old_event.current_to.present?).to be true
        new_event = request.current_request_event
        expect(new_event.current_to.nil?).to be true
      end
    end

    context 'destroying a request' do
      before do
        @old_request_id = request.id
        request.destroy
        @destroyed_ids = described_class.where(event_name: 'destroyed').pluck(:request_id)
      end

      it 'records a destroy RequestEvent for each request' do
        expect(@destroyed_ids).to eq [@old_request_id]
      end
    end
  end

  context 'find date when the request was moved to a particular state' do
    # rubocop:disable all
    it 'knows the date when passed' do
      event1 = create :request_event
      passed = Time.local(2009, 9, 1, 12, 0, 0)
      event2 = create :request_event, to_state: 'passed', current_from: passed
      event3 = create :request_event, to_state: 'later_state'
      expect(RequestEvent.date_for_state('passed').strftime('%Y%m%d')).to eq '20090901'
    end

    let(:request) { create :customer_request }

    it 'knows the date when passed through request' do
      event1 = create :request_event, request: request
      passed = Time.local(2009, 9, 1, 12, 0, 0)
      event2 = create :request_event, to_state: 'passed', current_from: passed, request: request
      event3 = create :request_event, to_state: 'later_state', request: request
      request.reload.request_events
      expect(request.date_for_state('passed').strftime('%Y%m%d')).to eq '20090901'
    end
    # rubocop:enable all
  end
end
