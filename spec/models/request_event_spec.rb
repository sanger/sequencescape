require 'rails_helper'

describe RequestEvent do
  RequestType.where(key: %w(
    illumina_b_std
    illumina_b_hiseq_2500_paired_end_sequencing
    illumina_c_multiplexed_library_creation
  )).all.each do |request_type|

    context "#{request_type.name} Requests" do
      before(:each) do
        well_with_sample_and_without_plate = create(:well_with_sample_and_without_plate)

        @request = request_type.new(
          asset: well_with_sample_and_without_plate,
          target_asset: create(:empty_well),
          request_metadata_attributes: { bait_library_id: BaitLibrary.last.id, insert_size: 200, fragment_size_required_from: 200, fragment_size_required_to: 201 }
        ).tap do |r|
          r.stub(:valid?) { true }
          r.save!
        end
      end

      context 'creating requests' do
        it 'should record a RequestEvent' do
          expect(RequestEvent.count).to eq 1
        end

        it 'should record a RequestEvent for each new Request' do
          expect(@request.request_events.count).to eq 1
          expect(@request.current_request_event.from_state).to be_nil
          expect(@request.current_request_event.to_state).to eq 'pending'
          expect(@request.current_request_event.event_name).to eq 'created'
          expect(@request.current_request_event.current_to).to be_nil
        end
      end

      context 'changing request state to start' do
        before(:each) do
          @request.start!
        end

        it 'should record new state change RequestEvents for each request' do
          expect(RequestEvent.count).to eq 2
        end

        it 'should record a new state change RequestEvent from "pending"' do
          event = @request.current_request_event
          expect(event.from_state).to eq 'pending'
        end

        it 'should record a new state change RequestEvent to "started"' do
          event = @request.current_request_event
          expect(event.to_state).to eq 'started'
        end

        it 'should set a current_to stamp on old events' do
          old_event = @request.request_events.order('id ASC').first
          expect(old_event.current_to.present?).to be true
          new_event = @request.current_request_event
          expect(new_event.current_to.nil?).to be true
        end
      end

      context 'destroying a request' do
        before(:each) do
          @old_request_id = @request.id
          @request.destroy
          @destroyed_ids = RequestEvent.where(event_name: 'destroyed').pluck(:request_id)
        end

        it 'should record a destroy RequestEvent for each request' do
          expect(@destroyed_ids).to eq [@old_request_id]
        end
      end
    end
  end

  RequestType.find_by(key: 'Transfer').tap do |request_type|
    context "#{request_type.name} Requests" do
      before(:each) do
        well_with_sample_and_without_plate = create(:well_with_sample_and_without_plate)

        @request = request_type.new(
          asset: well_with_sample_and_without_plate,
          target_asset: create(:empty_well),
          request_metadata_attributes: { bait_library_id: BaitLibrary.last.id, insert_size: 200, fragment_size_required_from: 200, fragment_size_required_to: 201 }
        ).tap do |r|
          r.stub(:valid?) { true }
          r.save!
        end
      end

      context 'creating requests' do
        it 'should not record a RequestEvent' do
          expect(RequestEvent.count).to eq 0
        end

        it 'should not record a RequestEvent for each new Request' do
          expect(@request.request_events.count).to eq 0
        end
      end

      context 'changing request state to start' do
        before(:each) do
          @request.start!
        end
        it 'should not record new state change RequestEvents for each request' do
          expect(RequestEvent.count).to eq 0
        end
      end

      context 'destroying a request' do
        before(:each) do
          @old_request_id = @request.id
          @request.destroy
          @destroyed_ids = RequestEvent.where(event_name: 'destroyed').pluck(:request_id)
        end

        it 'should not record a destroy RequestEvent for each request' do
          expect(@destroyed_ids).to eq []
        end
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
      expect(RequestEvent.all.date_for_state('passed').strftime('%Y%m%d')).to eq '20090901'
    end
    # rubocop:enable all
  end
end
