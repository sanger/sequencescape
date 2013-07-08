require 'test_helper'

class RequestEventTest < ActiveSupport::TestCase

  context "Requests" do
    setup do
      @request_types = RequestType.find_all_by_key(['Transfer','illumina_b_std','illumina_b_hiseq_2500_paired_end_sequencing','illumina_c_multiplexed_library_creation'])

      well_with_sample_and_without_plate = Factory(:well_with_sample_and_without_plate)
      @requests = []

      @request_types.each do |request_type|
        @requests << request_type.new(
            :asset => well_with_sample_and_without_plate,
            :target_asset => Factory(:empty_well),
            :request_metadata_attributes=>{:bait_library_id => BaitLibrary.last.id, :insert_size => 200, :fragment_size_required_from => 200, :fragment_size_required_to =>201}
          ).tap do |r|
          r.stubs(:valid?).returns(true)
          r.save!
        end
      end
    end

    context 'creating requests' do
      should 'record a RequestEvent for each RequestType.' do
        assert_equal @request_types.count,  RequestEvent.count
      end

      should 'record a RequestEvent for each new Request' do
        @requests.each do |request|
          assert_equal 1, request.request_events.count
          assert_equal nil, request.current_request_event.from_state
          assert_equal 'pending', request.current_request_event.to_state
          assert_equal 'created', request.current_request_event.event_name
          assert_equal nil, request.current_request_event.current_to
        end
        assert_equal @requests.count,  RequestEvent.count
      end

    end

    context 'changing request state to start' do
      setup do
          @requests.each { |r| r.start! }
      end
      should 'record new state change RequestEvents for each request' do
        assert_equal @requests.count * 2, RequestEvent.count
      end

      should 'record a new state change RequestEvent from "pending"' do
        @requests.each do |request|
          event = request.current_request_event
          assert_equal 'pending', event.from_state
        end
      end

      should 'record a new state change RequestEvent to "started"' do
        @requests.each do |request|
          event = request.current_request_event
          assert_equal 'started', event.to_state
        end
      end

      should 'set a current_to stamp on old events' do
        @requests.each do |request|
          old_event = request.request_events.first
          assert old_event.current_to.present?
          new_event = request.current_request_event
          assert new_event.current_to.nil?
        end
      end
    end

    context 'destroying a request' do
      setup do
        @old_request_ids = @requests.map(&:id)
        @requests.each { |r| r.destroy }
        @destroyed_ids = RequestEvent.find_all_by_event_name('destroyed').map(&:request_id)
      end

      should 'record a destroy RequestEvent for each request' do
        assert_equal @old_request_ids, @destroyed_ids
      end
    end

  end
end
