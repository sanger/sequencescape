# frozen_string_literal: true

require 'test_helper'

class BatchTest < ActiveSupport::TestCase
  context 'A batch' do
    context 'on its own' do
      setup { @batch = build(:batch) }

      should 'have begin in pending then change to started' do
        assert_equal 'pending', @batch.state
        @batch.start!(create(:user))

        assert_equal 'started', @batch.state
        assert_equal true, @batch.started?
      end
    end
  end

  context 'modifying request positions within a batch' do
    setup do
      @pipeline = create(:pipeline)

      # Weirdly, this is actually FASTER than factories by a substantial amount
      @requests = Array.new(10) { @pipeline.request_types.last.create! }
      @batch = create(:batch, requests: @requests, pipeline: @pipeline)
    end

    context '#assign_positions_to_requests!' do
      should 'raise an exception if no requests are specified' do
        assert_raises(StandardError) { @batch.assign_positions_to_requests!([]) }
      end

      should 'raise an exception if not all of the requests are specified' do
        assert_raises(StandardError) { @batch.assign_positions_to_requests!(@requests.slice(3, 5).map(&:id)) }
      end

      should 'move the requests to different positions' do
        @batch.assign_positions_to_requests!(@requests.reverse.map(&:id))

        expected = @requests.reverse.each_with_index.to_h { |request, index| [request.id, index + 1] }
        actual =
          @batch
            .batch_requests
            .each_with_object({}) { |batch_request, memo| memo[batch_request.request_id] = batch_request.position }

        assert_equal(expected, actual, 'Positions of requests do not match')
      end
    end
  end

  context 'when batch is created' do
    setup do
      @pipeline = create(:pipeline)
      @request1 = create(:request, request_type: @pipeline.request_types.first)
      @request2 = create(:request, request_type: @pipeline.request_types.first)

      @batch = create(:batch, requests: [@request1, @request2], pipeline: @pipeline)
    end

    should 'be able to call start_requests' do
      assert_nothing_raised { @batch.start_requests }
    end

    should 'have initially have a pending status for batch requests' do
      assert_equal 'pending', @batch.requests.first.state
      @batch.start!(create(:user))

      assert_equal 'started', @batch.state
      assert_equal 'started', @batch.requests.reload.first.state
    end

    context '#remove_request_ids' do
      context 'with 2 requests' do
        context 'where 1 needs to be removed' do
          setup do
            @batch_requests_count = @batch.requests.count
            @batch.remove_request_ids([@request2.id], 'Reason', 'Comment')
          end
          should 'leave 1 requests behind' do
            @batch.requests.reload

            assert_includes @batch.requests, @request1
            assert @batch.requests.exclude?(@request2)
            assert_equal @batch_requests_count - 1, @batch.requests.count
          end
        end
      end
    end
  end

  context 'batch #has_event(event_name)' do
    setup do
      @batch = create(:batch)
      @batch.start!(create(:user))

      @lab_event = LabEvent.new
    end
    context 'when a batch is not associated with any events, it' do
      should 'return false.' do
        assert_equal false,
                     @batch.has_event('Tube layout verified'),
                     '#has_event should return false if an event is not found'
      end
    end
    context 'when a batch has a LabEvent' do
      setup do
        @lab_event.description = nil
        @batch.lab_events << @lab_event
      end
      should 'it should only return if the description is set' do
        assert_equal false, @batch.has_event('Tube layout verified')
        @lab_event.description = 'Tube layout verified'
        @batch.lab_events << @lab_event

        assert_equal true, @batch.has_event('Tube layout verified')
      end
    end
  end

  context '#requests_by_study' do
    setup do
      @pipeline = create(:pipeline, locale: 'Internal')
      @batch = create(:batch, pipeline: @pipeline)
      @study1 = create(:study)
    end

    context 'with no requests' do
      should 'return an empty array' do
        assert_empty @batch.requests.for_studies(@study1)
      end
    end

    context 'with 1 request' do
      setup do
        @study2 = create(:study)
        @request1 = create(:request, request_type: @pipeline.request_types.last, study: @study1, batch: @batch)
      end

      should 'return correct studies' do
        assert_includes @batch.requests.for_studies(@study1), @request1
        assert_empty @batch.requests.for_studies(@study2).all
      end
    end

    context 'with 2 requests from different studies' do
      setup do
        @study2 = create(:study)
        @study3 = create(:study)
        @request1 = create(:request, request_type: @pipeline.request_types.last, study: @study1)
        @request2 = create(:request, request_type: @pipeline.request_types.last, study: @study2)
        @batch.requests << @request1 << @request2
      end

      should 'return correct studies' do
        assert_includes @batch.requests.for_studies(@study1), @request1
        assert_includes @batch.requests.for_studies(@study2), @request2
        assert_empty @batch.requests.for_studies(@study3).all
      end
    end
  end

  context '#plate_ids_in_study' do
    setup do
      @pipeline = create(:pipeline)
      @batch = create(:batch, pipeline: @pipeline)
      @study1 = create(:study)
    end

    context 'with no requests' do
      should 'not return plate ids' do
        assert_empty @batch.plate_ids_in_study(@study1)
      end
    end

    context 'with 2 request on a different plates' do
      setup do
        @study2 = create(:study)
        @plate1 = create(:plate)
        @well1 = create(:well, plate: @plate1)

        @plate2 = create(:plate)
        @well2 = create(:well, plate: @plate2)

        @batch.requests = [
          @pipeline.request_types.last.create!(study: @study1, asset: @well1),
          @pipeline.request_types.last.create!(study: @study1, asset: @well2)
        ]
      end
      should 'return 1 plate id where they are in given study' do
        assert_equal 2, @batch.plate_ids_in_study(@study1).size
        assert_includes @batch.plate_ids_in_study(@study1), @plate1.id
        assert_includes @batch.plate_ids_in_study(@study1), @plate2.id
      end
      should 'not return a plate id where they are not in the given study' do
        assert_not @batch.plate_ids_in_study(@study2).include?(@plate1.id)
      end
    end
  end

  context 'Batch' do
    should belong_to :user
    should belong_to :pipeline
    should belong_to :assignee
    should have_many :failures
    should have_many :lab_events
    should have_many :requests

    should_have_instance_methods :assigned_user, :start, :fail, :workflow, :started?, :released?, :qc_state

    setup { @pipeline = create(:sequencing_pipeline, name: 'Pipeline for BatchTest') }

    context 'create requests' do
      setup do
        @requests = create_list(:request, 4, request_type: @pipeline.request_types.last, target_asset: nil)
        @asset_count = Receptacle.count
        @batch = @pipeline.batches.create!(requests: @requests)
      end

      should 'create target assets for each request' do
        # This is dependent of some aspects of pipelines and request types.
        # Its all a bit convoluted and inconsistent.
        assert_equal 4, Receptacle.count - @asset_count, 'Expected Receptacle.count to change by 4'
        @requests.each { |r| assert_predicate r.reload.target_asset, :present?, 'Request has no target asset' }
      end

      should 'not have same asset name' do
        assert_not_equal Labware.first.name, Labware.last.name
      end

      should 'create a batch_request for every associated request' do
        assert_equal @requests.size, @batch.batch_requests.count
      end

      should 'have request position corresponding to the request creation order' do
        @batch.batch_requests.each { |br| assert_equal @requests[br.position - 1].id, br.request_id }
      end
    end

    context 'when a batch is failed' do
      setup do
        # send_fail_event will be used once since only one request is not a resource /@request1
        #        EventSender.expects(:send_fail_event).returns(true).times(1)
        EventSender.stubs(:send_fail_event).returns(true)
        @control = create(:sample_tube, resource: true)

        @batch = @pipeline.batches.create!
        @request1, @request2 =
          @batch.requests = [
            @pipeline.request_types.last.create!,
            @pipeline.request_types.last.create!(asset: @control)
          ]

        @reason = 'PCR not enough'
        @comment = 'Hey! sing Are we human?'
      end

      should 'return true if batch has failed and have 2 requests' do
        @batch.fail(@reason, @comment)

        assert_equal 'fail', @batch.production_state
        assert_predicate @batch, :failed?
        assert_equal 2, @batch.request_count
      end

      should 'raise an exception if you try and ignore requests' do
        assert_raise StandardError do
          @batch.fail(@reason, @comment, :ignore_requests)
        end
      end

      context 'create failures' do
        setup do
          @bfpc_initial = @batch.failures.count
          @bps_initial = @batch.production_state
          @batch.fail(@reason, @comment)
        end

        should 'have matching batch requests' do
          assert_equal @request1.id, @batch.requests.first.id
          assert_equal @request2.id, @batch.requests.last.id
        end

        should 'change @batch.failures.count from 0 to 1' do
          assert_equal 0, @bfpc_initial
          assert_equal 1, @batch.failures.count
        end

        should 'change @batch.production_state from 0 to 1' do
          assert_nil @bps_initial
          assert_equal 'fail', @batch.production_state
        end
      end
    end

    context 'when specific requests in a batch are failing' do
      setup do
        @batch = @pipeline.batches.create!
        @request_type = @pipeline.request_types.last
        @request1, @request2 = @batch.requests = create_list(:request, 2, request_type: @request_type)
        @reason = 'PCR not enough'
        @comment = 'Hey! Are we human?'
      end

      context 'fail requests' do
        setup do
          # The event sender actually does the failures.
          EventSender.expects(:send_fail_event).with(@request1, @reason, @comment, @batch.id).returns(true).times(1)
          params = [@request1.id.to_s]
          @batch.fail_requests(params, @reason, @comment)
        end

        should 'not fail the batch' do
          assert_not @batch.failed?
        end

        should 'create failures on failed requests' do
          assert_equal 1, @request1.failures.count
        end
      end

      context 'fail the batch' do
        setup do
          EventSender.expects(:send_fail_event).returns(true).times(2)
          @requests = [@request1.id.to_s, @request2.id.to_s]
          @request1.expects(:terminated?).returns(true).times(1)
          @request2.expects(:terminated?).returns(true).times(1)

          assert_empty @batch.failures
          @batch.fail_requests(@requests, @reason, @comment)
        end

        should 'if all the requests within the batch are failing, fail the batch too' do
          assert_predicate @batch, :failed?
        end

        should 'create a batch failure' do
          assert_predicate @batch.failures, :one?
        end
      end
    end

    context '#public methods' do
      setup do
        @asset1 = create(:sample_tube, barcode: '123456')
        @asset2 = create(:sample_tube, barcode: '654321')

        @request1 = @pipeline.request_types.last.create!(asset: @asset1)
        @request2 = @pipeline.request_types.last.create!(asset: @asset2)

        @batch = @pipeline.batches.create!
        @batch.batch_requests.create!(request: @request1, position: 2)
        @batch.batch_requests.create!(request: @request2, position: 1)
        @batch.reload
      end

      should 'return ordered requests' do
        v = @batch.ordered_requests

        assert_equal @request2, v[0]
        assert_equal @request1, v[1]
      end

      should 'return true if the tubes are scanned in in the correct order' do
        number_of_batch_events = @batch.lab_events.size

        assert @batch.verify_tube_layout([@asset2.machine_barcode, @asset1.machine_barcode])
        assert_equal number_of_batch_events + 1, @batch.lab_events.size
      end

      should 'return false and add errors to the batch if the tubes are not in the correct order' do
        number_of_batch_events = @batch.lab_events.size

        assert_not @batch.verify_tube_layout([@asset1.machine_barcode, @asset2.machine_barcode])
        assert_not @batch.errors.empty?
        assert_equal number_of_batch_events, @batch.lab_events.size
      end

      should 'return empty assigned user' do
        assert '', @batch.assigned_user
      end

      should 'return user login' do
        @user = create(:user)
        @batch.assignee_id = @user.id

        assert 'lg1', @batch.assigned_user
      end

      context 'with control' do
        setup do
          @control = create(:sample_tube, resource: true)
          @request = @pipeline.request_types.last.create!(asset: @control)
          @batch.batch_requests.create!(request: @request, position: 3)
        end

        should 'return true a request has resource' do
          assert_predicate @batch, :has_control?
        end

        should 'return the first request with resource' do
          assert_equal @request, @batch.control
        end
      end

      should 'return true if self has item_limit' do
        @pipeline.workflow.update!(item_limit: 4)
        @batch.reload

        assert_predicate @batch, :has_limit?
      end

      context 'underrun' do
        setup { @pipeline.workflow.update!(item_limit: 4) }

        should 'return POSITIVE difference between batch.request_limit and batch.request_count' do
          assert_equal 2, @batch.underrun
        end

        should 'return NEGATIVE difference between batch.request_limit and batch.request_count' do
          @batch.batch_requests.create!(request: @pipeline.request_types.last.create!, position: 3)
          @batch.batch_requests.create!(request: @pipeline.request_types.last.create!, position: 4)
          @batch.batch_requests.create!(request: @pipeline.request_types.last.create!, position: 5)

          assert_equal(-1, @batch.underrun)
        end
      end

      should 'return 0 if batch has no request_limit set' do
        @pipeline.workflow.update!(item_limit: nil)

        assert_equal 0, @batch.underrun
      end
    end

    context '#QC related' do
      context '#qc_criteria_received' do
        setup { @batch = @pipeline.batches.create! }

        should 'have pending as qc_state until flag is set' do
          assert_equal 'qc_pending', @batch.qc_state
          @batch.qc_state = 'qc_manual_in_progress'
          @batch.qc_complete

          assert_equal 'qc_completed', @batch.qc_state
        end
      end
    end

    context '#reset!' do
      context 'once started' do
        setup { @batch = create(:batch, pipeline: @pipeline, state: 'started') }

        should 'raise an exception' do
          assert_raise AASM::InvalidTransition do
            @batch.reset!(@user)
          end
        end
      end

      {
        sequencing_pipeline: :sequencing_request_with_assets,
        pipeline: :request
      }.each do |pipeline_type, request_factory|
        context "of a #{pipeline_type}" do
          setup do
            @pipeline = create(pipeline_type)
            @batch = create(:batch, pipeline: @pipeline)
            @pending_request = create(request_factory, request_type: @pipeline.request_types.last)
            @pending_request_2 = create(request_factory, request_type: @pipeline.request_types.last)
            @batch.requests << @pending_request << @pending_request_2
          end

          # Separate context because we need to setup the DB first and we cannot check the changes made.
          context 'checking DB changes' do
            setup do
              @asset_count = Receptacle.count
              @batchrequest_count = BatchRequest.count
              @request_count = Request.count
              @batch_count = Batch.count
              @batch.reset!(@user)
            end

            should 'remove the requests from the batch but not destroy them' do
              assert_equal(-2, BatchRequest.count - @batchrequest_count, 'Expected BatchRequest.count to change by -2')
              assert_equal(0, Receptacle.count - @asset_count, 'Expected Asset.count to not change')
              assert_equal 0, Request.count - @request_count, 'Expected Request.count to change by 0'
              assert_equal 0, Batch.count - @batch_count, 'Expected Batch.count to change by 0'
            end

            should 'transition to discarded' do
              assert_equal('discarded', @batch.state)
            end
          end
        end
      end
    end

    context '#qc_previous_state!' do
      setup do
        @user = create(:user)
        @batch = create(:batch, pipeline: @pipeline)
        @batch.update!(qc_state: 'qc_completed')
      end
      should 'move batch to previous qc state' do
        assert_equal 'qc_completed', @batch.qc_state
        @batch.qc_previous_state!(@user)

        assert_equal 'qc_manual_in_progress', @batch.qc_state
        @batch.qc_previous_state!(@user)

        assert_equal 'qc_manual', @batch.qc_state
      end
    end

    context '#swap' do
      # We must test swapping requests at different and same positions, as well as ones which would clash if not
      # adjusted
      [[3, 4], [4, 4], [2, 1]].each do |left_position, right_position| # rubocop:todo Metrics/BlockLength
        context "when swapping #{left_position} and #{right_position}" do
          setup do
            # Create a batch with a couple of requests positioned appropriately
            @left_batch = create(:batch, pipeline: @pipeline)
            @original_left_request = create(:batch_request, batch_id: @left_batch.id, position: left_position)
            create(:batch_request, batch_id: @left_batch.id, position: 1)

            # Now create another batch that we'll swap the requests between
            @right_batch = create(:batch, pipeline: @pipeline)
            @original_right_request = create(:batch_request, batch_id: @right_batch.id, position: right_position)
            create(:batch_request, batch_id: @right_batch.id, position: 2)

            @user = create(:user)
          end

          should 'swap lanes given 2 batches and swap requests.' do
            assert(
              @left_batch.swap(
                @user,
                'batch_1' => {
                  'id' => @left_batch.id.to_s,
                  'lane' => left_position.to_s
                },
                'batch_2' => {
                  'id' => @right_batch.id.to_s,
                  'lane' => right_position.to_s
                }
              )
            )

            # The two requests should have been swapped
            assert_equal(
              @original_right_request.request,
              @left_batch.batch_requests.at_position(left_position).first.request
            )
            assert_equal(
              @original_left_request.request,
              @right_batch.batch_requests.at_position(right_position).first.request
            )
          end
        end
      end
    end

    context '#detach_request' do
      setup do
        @library_prep_pipeline = create(:pipeline, name: 'Library Prep Pipeline')
        @lib_prep_batch = create(:batch, pipeline: @library_prep_pipeline)
        @sample_tube = create(:sample_tube, name: 'sample tube 1')
        @library_tube = create(:library_tube, name: 'lib tube 1')
        @lib_prep_request = create(:library_request, state: 'started', asset: @sample_tube, target_asset: @library_tube)
        @pe_seq_request = create(:sequencing_request, state: 'pending', asset: @library_tube)
        @lib_prep_batch.requests << @lib_prep_request
      end

      context 'detaching' do
        setup { @lib_prep_batch.detach_request(@lib_prep_request) }

        context 'from the input side of the batch' do
          setup { @lib_prep_request.reload }

          should 'leave the target asset from the request but remove the request from the batch' do
            assert_equal @lib_prep_request.target_asset, @library_tube.receptacle
            assert_includes @lib_prep_batch.requests, @lib_prep_request
          end
        end

        context 'from the output side of the batch' do
          setup { @pe_seq_request.reload }

          should 'not remove the asset from the request' do
            assert_equal @pe_seq_request.asset, @library_tube.receptacle
          end
        end
      end

      should 'not raise any exceptions if the request does not have a target asset' do
        @lib_prep_request.target_asset = nil
        @lib_prep_request.save

        assert_nothing_raised { @lib_prep_batch.detach_request(@lib_prep_request) }
      end

      should 'not raise any exceptions if the request does not have an asset' do
        @pe_seq_request.asset = nil
        @pe_seq_request.save

        assert_nothing_raised { @lib_prep_batch.detach_request(@lib_prep_request) }
      end
    end

    context '#last_completed_task' do
      setup do
        @library_prep_pipeline = create(:pipeline, name: 'Library Prep Pipeline')
        @task1 = create(:task, workflow: @library_prep_pipeline.workflow, name: 'Task 1', sorted: 0)
        @task2 = create(:task, workflow: @library_prep_pipeline.workflow, name: 'Task 2', sorted: 1)
        @task3 = create(:task, workflow: @library_prep_pipeline.workflow, name: 'Task 3', sorted: 2)

        @batch = create(:batch, pipeline: @library_prep_pipeline, state: 'started')
        @batch.requests << @library_prep_pipeline.request_types.last.create!(state: 'started')

        # NO idea why descriptors are added twice here, or why the descriptors
        # implementation appears to be so complicated. I've converted this from
        # mocks to use factories instead, I'm keeping the duplicate tasks
        # until I can work out why they were added.
        @event1 = create(:lab_event, description: 'Complete', batch: @batch)
        @event1.add_new_descriptor 'task_id', @task1.id.to_s
        @event1.add_new_descriptor 'task_id', @task1.id.to_s

        @event2 = create(:lab_event, description: 'Complete', batch: @batch)
        @event2.add_new_descriptor 'task_id', @task2.id.to_s
        @event2.add_new_descriptor 'task_id', @task2.id.to_s

        @batch.lab_events = [@event1, @event2]
      end

      should 'return the last task the batch completed' do
        assert_equal 2, @batch.lab_events.size
        assert_equal @task2, @batch.last_completed_task
      end
    end
  end

  context 'completing a batch' do
    setup do
      @batch, @user = create(:batch), create(:user)
      @batch.start!(@user)
    end

    should 'check that with the pipeline that the batch is valid' do
      @batch.complete!(@user)
    end
  end

  context '#npg_set_state' do
    setup do
      # JG: The QC state machine on batch is near non-existent, and all events
      # just push the batch into the next state. Here we advance the qc_state
      # to try and model what appears to be the intended behaviour.
      @pipeline = create(:sequencing_pipeline)
      @batch = create(:batch, pipeline: @pipeline)
      @batch.update!(qc_state: 'qc_manual_in_progress')
      @requests =
        create_list(:sequencing_request_with_assets, 2, state: 'started', request_type: @pipeline.request_types.first)
      @batch.requests = @requests
    end

    context 'when all requests are passed' do
      setup do
        @requests.each { |r| r.events.create!(family: 'pass') }
        @batch.npg_set_state
      end

      should 'should complete the batch' do
        assert_equal 'qc_completed', @batch.qc_state
      end
    end

    context 'when not all requests are passed' do
      setup do
        @requests.first.events.create!(family: 'pass')
        @batch.npg_set_state
      end

      should 'should not complete the batch' do
        assert_equal 'qc_manual_in_progress', @batch.qc_state
      end
    end

    # JG: Resources are a little clunky, they essentially indicate controls.
    # They don't tend to get used much any more, and I'm not entirely
    # clear if they have any meaningful distinction from control requests.
    context 'when some assets are a resource' do
      setup do
        @batch.requests.first.events.create!(family: 'pass')
        @batch.requests.last.asset.update!(resource: true)
        @batch.npg_set_state
      end

      should 'should complete the batch' do
        assert_equal 'qc_completed', @batch.qc_state
      end
    end
  end

  context 'ready? all requests before creating batch' do
    setup do
      @library_tube = create(:library_tube, sample_count: 1)
      @library_creation_request =
        create(:library_creation_request_for_testing_sequencing_requests, target_asset: @library_tube)
      @pipeline = create(:sequencing_pipeline)

      @library_tube.create_scanned_into_lab_event!(content: '2018-01-01')

      @batch = build(:batch, pipeline: @pipeline)
      @request_type = @batch.pipeline.request_types.first
      @sequencing_request = create(:sequencing_request, asset: @library_tube, request_type: @request_type)
      @batch.requests << @sequencing_request
    end

    should 'check that I cannot create a batch with invalid requests (ready?)' do
      assert_equal false, @batch.valid?
    end

    should 'check that I can create a batch with valid requests ready?' do
      @library_creation_request.start
      @library_creation_request.pass!

      assert_predicate @batch, :valid?
    end
  end
end
