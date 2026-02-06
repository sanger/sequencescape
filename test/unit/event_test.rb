# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  context 'An Event' do
    setup { Study.destroy_all }
    should belong_to :eventful

    should_have_instance_methods :eventful_id, :eventful_type
    should_have_instance_methods :message, :family
    should_have_instance_methods :identifier, :location
    should_have_instance_methods :request?

    context 'when creating' do
      context "when 'descriptor' key is not blank" do
        context 'should add production data' do
          setup { @event = Event.create(descriptor_key: '') }

          should 'be valid' do
            @event.valid?
          end
        end
      end

      context "when 'descriptor' key is blank" do
        context 'should not add production data' do
          setup { @event = Event.create }

          should 'be valid' do
            @event.valid?
          end
        end
      end
    end

    context 'when related to a Request' do
      setup do
        @study = create(:study)
        @request = create(:request, study: @study)
        @settings = {
          eventful_id: @request.id,
          eventful_type: 'Request',
          family: 'QC Analysis',
          identifier: 'ID',
          location: 'Loc'
        }

        assert_predicate @request, :pending?
      end

      context 'when QC message is unknown' do
        setup do
          @original_state = @request.state
          @settings[:message] = "'I am the hungriest animal of all!', said the Ravenous Beast."
          @event = Event.create @settings
          @request.reload
        end

        should 'leave request status as was' do
          assert_equal @original_state, @request.state
        end
      end
    end

    context '#update_request' do
      setup do
        @study = create(:study)
        @request = create(:request, study: @study, state: 'started')
        @settings = {
          eventful_id: @request.id,
          eventful_type: 'Request',
          identifier: 'ID',
          location: 'Loc',
          message: 'updating request'
        }

        assert_predicate @request, :started?
      end

      context 'when pass' do
        setup do
          @settings[:family] = 'pass'
          @settings[:descriptor_key] = 'the_two_step'
          @event = Event.create(@settings)
          @request.reload
        end

        should 'pass request' do
          assert_predicate @request, :passed?
        end
      end

      context 'when fail' do
        setup { @settings[:family] = 'fail' }

        context 'when not LP or MX LP' do
          setup do
            @settings[:descriptor_key] = 'failure'
            @event = Event.create(@settings)
            @request.reload
          end
        end

        context 'when Library Prep' do
          setup do
            @settings[:descriptor_key] = 'library_creation_complete'
            @event = Event.create(@settings)
            @request.reload
          end

          should 'update request state' do
            assert_predicate @request, :failed?
          end
        end
      end
    end

    context 'when created with a' do
      setup do
        @library_creation_request_type = create(:request_type, name: 'Library creation', key: 'library_creation')
        @mx_library_creation_request_type =
          create(:request_type, name: 'Multiplexed library creation', key: 'multiplexed_library_creation')
        @pe_sequencing_request_type = create(:request_type, name: 'Paired end sequencing', key: 'paired_end_sequencing')

        @control = create(:sample_tube, resource: true)

        @library_creation_request = create(:request, request_type: @library_creation_request_type)
        @multiplexed_library_creation_request = create(:request, request_type: @mx_library_creation_request_type)
        @pe_sequencing_request = create(:request, request_type: @pe_sequencing_request_type)
        @request_for_control =
          create(:request, request_type: @pe_sequencing_request_type, asset: @control, state: 'started')
        @requests = [@library_creation_request, @multiplexed_library_creation_request, @pe_sequencing_request]
      end

      # pass message
      # { :eventful_id => request_id, :eventful_type => 'Request', :family => "pass", :content => reason,
      #   :message => comment, :identifier => batch_id, :descriptor_key => "pass" }
      context 'a pass message' do
        setup do
          @requests.each do |request|
            request.state = 'started'
            request.save
          end

          @request_with_no_attempts = @requests.first

          @lib_prep_event =
            Event.create(
              eventful_id: @library_creation_request.id,
              eventful_type: 'Request',
              family: 'pass',
              content: '',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'pass'
            )
          @mx_lib_prep_event =
            Event.create(
              eventful_id: @multiplexed_library_creation_request.id,
              eventful_type: 'Request',
              family: 'pass',
              content: '',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'pass'
            )
          @pe_sequencing_event =
            Event.create(
              eventful_id: @pe_sequencing_request.id,
              eventful_type: 'Request',
              family: 'pass',
              content: '',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'pass'
            )
          @control_event =
            Event.create(
              eventful_id: @request_for_control.id,
              eventful_type: 'Request',
              family: 'pass',
              content: '',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'pass'
            )
        end

        should 'create valid events' do
          # must create an event correctly
          assert_predicate @lib_prep_event, :valid?
          assert_predicate @mx_lib_prep_event, :valid?
          assert_predicate @pe_sequencing_event, :valid?
        end

        # must update the request correctly
        should 'set the state of the requests to passed' do
          @library_creation_request.reload
          @multiplexed_library_creation_request.reload
          @pe_sequencing_request.reload
          @request_for_control.reload

          assert_predicate @library_creation_request, :passed?
          assert_predicate @multiplexed_library_creation_request, :passed?
          assert_predicate @pe_sequencing_request, :passed?
          assert_predicate @request_for_control, :passed?
        end
      end

      # fail message
      # { :eventful_id => request_id, :eventful_type => 'Request', :family => "fail", :content => reason,
      # :message => comment, :identifier => batch_id, :descriptor_key => "failure" }
      context 'fail message' do
        setup do
          @requests.each do |request|
            request.state = 'started'
            request.save
          end

          @request_for_control.state = 'started'
          @request_with_no_attempts = @requests.first

          @lib_prep_event =
            Event.create(
              eventful_id: @library_creation_request.id,
              eventful_type: 'Request',
              family: 'fail',
              content: 'Test reason',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'failure'
            )
          @mx_lib_prep_event =
            Event.create(
              eventful_id: @multiplexed_library_creation_request.id,
              eventful_type: 'Request',
              family: 'fail',
              content: 'Test reason',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'failure'
            )
          @pe_sequencing_event =
            Event.create(
              eventful_id: @pe_sequencing_request.id,
              eventful_type: 'Request',
              family: 'fail',
              content: 'Test reason',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'failure'
            )
          @control_event =
            Event.create(
              eventful_id: @request_for_control.id,
              eventful_type: 'Request',
              family: 'fail',
              content: 'Test reason',
              message: 'test comment',
              identifier: 1234,
              descriptor_key: 'failure'
            )
        end

        # must create an event correctly
        # must update the request correctly
        should 'set the state of the requests to failed' do
          @library_creation_request.reload
          @multiplexed_library_creation_request.reload
          @pe_sequencing_request.reload
          @request_for_control.reload

          assert_predicate @library_creation_request, :failed?
          assert_predicate @multiplexed_library_creation_request, :failed?
          assert_predicate @pe_sequencing_request, :failed?
          assert_predicate @request_for_control, :failed?
        end
      end

      context 'cancel message' do
        # This doesn't do anything yet.
      end

      context 'request update' do
        setup do
          @requests.each do |request|
            request.state = 'started'
            request.save
          end

          # :eventful_id => request_id, :eventful_type => 'Request', :family => family, :message => message
          @lib_prep_event =
            Event.create(
              eventful_id: @library_creation_request.id,
              eventful_type: 'Request',
              family: 'complete',
              message: 'Completed pipeline'
            )
          @mx_lib_prep_event =
            Event.create(
              eventful_id: @multiplexed_library_creation_request.id,
              eventful_type: 'Request',
              family: 'complete',
              message: 'Completed pipeline'
            )
          @pe_sequencing_event =
            Event.create(
              eventful_id: @pe_sequencing_request.id,
              eventful_type: 'Request',
              family: 'complete',
              message: 'Completed pipeline'
            )
        end

        should 'correctly update the requests' do
          @library_creation_request.reload
          @multiplexed_library_creation_request.reload
          @pe_sequencing_request.reload

          assert_predicate @library_creation_request, :started?
          assert_predicate @multiplexed_library_creation_request, :started?
          assert_predicate @pe_sequencing_request, :started?
        end
      end
    end
  end
end
