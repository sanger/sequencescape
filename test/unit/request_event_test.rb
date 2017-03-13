# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

require 'test_helper'

class RequestEventTest < ActiveSupport::TestCase
  RequestType.where(key: %w(
illumina_b_std
illumina_b_hiseq_2500_paired_end_sequencing
illumina_c_multiplexed_library_creation
)).all.each do |request_type|

    context "#{request_type.name} Requests" do
      setup do
        well_with_sample_and_without_plate = create(:well_with_sample_and_without_plate)

        @request = request_type.new(
            asset: well_with_sample_and_without_plate,
            target_asset: create(:empty_well),
            request_metadata_attributes: { bait_library_id: BaitLibrary.last.id, insert_size: 200, fragment_size_required_from: 200, fragment_size_required_to: 201 }
          ).tap do |r|
          r.stubs(:valid?).returns(true)
          r.save!
        end
      end

      context 'creating requests' do
        should 'record a RequestEvent' do
          assert_equal 1, RequestEvent.count
        end

        should 'record a RequestEvent for each new Request' do
          assert_equal 1, @request.request_events.count
          assert_equal nil, @request.current_request_event.from_state
          assert_equal 'pending', @request.current_request_event.to_state
          assert_equal 'created', @request.current_request_event.event_name
          assert_equal nil, @request.current_request_event.current_to
        end
      end

      context 'changing request state to start' do
        setup do
          @request.start!
        end
        should 'record new state change RequestEvents for each request' do
          assert_equal 2, RequestEvent.count
        end

        should 'record a new state change RequestEvent from "pending"' do
          event = @request.current_request_event
          assert_equal 'pending', event.from_state
        end

        should 'record a new state change RequestEvent to "started"' do
          event = @request.current_request_event
          assert_equal 'started', event.to_state
        end

        should 'set a current_to stamp on old events' do
          old_event = @request.request_events.order('id ASC').first
          assert old_event.current_to.present?
          new_event = @request.current_request_event
          assert new_event.current_to.nil?
        end
      end

      context 'destroying a request' do
        setup do
          @old_request_id = @request.id
          @request.destroy
          @destroyed_ids = RequestEvent.where(event_name: 'destroyed').pluck(:request_id)
        end

        should 'record a destroy RequestEvent for each request' do
          assert_equal [@old_request_id], @destroyed_ids
        end
      end
    end
  end

  RequestType.find_by(key: 'Transfer').tap do |request_type|
    context "#{request_type.name} Requests" do
      setup do
        well_with_sample_and_without_plate = create(:well_with_sample_and_without_plate)

        @request = request_type.new(
            asset: well_with_sample_and_without_plate,
            target_asset: create(:empty_well),
            request_metadata_attributes: { bait_library_id: BaitLibrary.last.id, insert_size: 200, fragment_size_required_from: 200, fragment_size_required_to: 201 }
          ).tap do |r|
          r.stubs(:valid?).returns(true)
          r.save!
        end
      end

      context 'creating requests' do
        should 'not record a RequestEvent' do
          assert_equal 0, RequestEvent.count
        end

        should 'not record a RequestEvent for each new Request' do
          assert_equal 0, @request.request_events.count
        end
      end

      context 'changing request state to start' do
        setup do
          @request.start!
        end
        should 'not record new state change RequestEvents for each request' do
          assert_equal 0, RequestEvent.count
        end
      end

      context 'destroying a request' do
        setup do
          @old_request_id = @request.id
          @request.destroy
          @destroyed_ids = RequestEvent.where(event_name: 'destroyed').pluck(:request_id)
        end

        should 'not record a destroy RequestEvent for each request' do
          assert_equal [], @destroyed_ids
        end
      end
    end
  end
end
