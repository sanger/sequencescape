require File.dirname(__FILE__) + '/../test_helper'

class RequestEventTest < ActiveSupport::TestCase

  context "When using Non-Pulldown RequestTypes" do
    setup do
      @request_types = RequestType.all

      @requests = []

      @request_types.each do |request_type|
        @requests << request_type.new.tap do |r| 
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
        end
        assert_equal @requests.count,  RequestEvent.count
      end

    end

    context 'changing request state to hold' do
      setup do
          @requests.each { |r| r.hold! }
      end
      should 'record new state change RequestEvents for each request' do
        assert_equal @requests.count * 2, RequestEvent.count
      end

      should 'record new state change RequestEvents with the event name of "hold"' do
        @requests.each do |request|
          event = request.request_events.last
          assert_equal 'hold', event.event_name
        end
      end

      should 'record a new state change RequestEvent from "pending"' do
        @requests.each do |request|
          event = request.request_events.last
          assert_equal 'pending', event.from_state
        end
      end

      should 'record a new state change RequestEvent to "hold"' do
        @requests.each do |request|
          event = request.request_events.last
          assert_equal 'hold', event.to_state
        end
      end
    end

    context 'destoying a request' do
      setup do
        @old_request_ids = @requests.map(&:id)
        @requests.each { |r| r.destroy }

        @destroyed_ids = RequestEvent.find_all_by_event_name('destroy').map(&:request_id)
      end

      should 'record a destroy RequestEvent for each request' do
        assert_equal @old_request_ids, @destroyed_ids
      end
    end


    context "changing a request's study" do
      setup do
        @new_study     = Factory(:study)
        @old_study_id  = @requests.first.initial_study_id

        @requests.each do |request|
          request.update_attributes(
            :initial_study_id => @new_study.id
          )
        end

        @request_events = RequestEvent.find_all_by_study_id(@new_study.id)
      end

      should 'record a study change RequestEvent' do
        @request_events.each do |request_event|
          assert_equal  "ATTRIBUTE: initial_study_id UPDATED: #{@old_study_id} -> #{@new_study.id}", request_event.event_name
        end
      end
    end

    context "changing a request's project" do
      setup do
        @new_project     = Factory(:project)
        @old_project_id  = @requests.first.initial_project_id

        @requests.each do |request|
          request.update_attributes(
            :initial_project_id => @new_project.id
          )
        end

        @request_events = RequestEvent.find_all_by_project_id(@new_project.id)
      end

      should 'record a project change RequestEvent' do
        @request_events.each do |request_event|
          assert_equal  "ATTRIBUTE: initial_project_id UPDATED: #{@old_project_id} -> #{@new_project.id}", request_event.event_name
        end
      end

    end
  end
end
