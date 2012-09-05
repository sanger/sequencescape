require "test_helper"

class BatchTest < ActiveSupport::TestCase
  def setup
    @pipeline = Factory :pipeline,
      :name          => 'Test pipeline',
      :workflow      => LabInterface::Workflow.create!(:item_limit => 8),
      :request_types => [ Factory(:request_type, :request_class      => Request, :order => 1) ]
  end

  context "A batch" do
    setup do
      @batch = @pipeline.batches.build
    end

    should "have begin in pending then change to started" do
      assert_equal @batch.aasm_current_state, :pending
      @batch.start!(Factory(:user))
      assert_equal @batch.aasm_current_state, :started
      assert_equal @batch.started?, true
    end

    context "with a pipeline" do
      setup do
        @batch = @pipeline.batches.create!
      end
      context "workflow is internal and released?" do
        setup do
          @pipeline.workflow.update_attributes!(:locale => 'Internal')
        end

        should "initially not be #externally_released? then be #externally_released?" do
          assert_equal @batch.externally_released?, false
          @batch.release!(Factory(:user))
          assert_equal @batch.externally_released?, true
        end
      end

      context "workflow is external and released?" do
        setup do
          @pipeline.workflow.update_attributes!(:locale => 'External')
        end

        should "initially not be #internally_released? then be #internally_released? and return the pipelines first workflow" do
          assert_equal @batch.internally_released?, false
          @batch.release!(Factory(:user))
          assert_equal @batch.internally_released?, true
        end
      end
    end
  end

  context "Batch#add_control" do
    setup do
      @control = Factory :control
      @batch = @pipeline.batches.create!
      @batch.add_control(@control.name, 2)
    end

    should_change("BatchRequest.count", :by => 2) { BatchRequest.count }
  end

  context 'modifying request positions within a batch' do
    setup do
      @requests = (1..10).map { |_| @pipeline.request_types.last.create! }
      @batch    = @pipeline.batches.create!(:requests => @requests)
    end

    context "#assign_positions_to_requests!" do
      should 'raise an exception if no requests are specified' do
        assert_raises(StandardError) { @batch.assign_positions_to_requests!([]) }
      end

      should 'raise an exception if not all of the requests are specified' do
        assert_raises(StandardError) { @batch.assign_positions_to_requests!(@requests.slice(3, 5).map(&:id)) }
      end

      should 'move the requests to different positions' do
        @batch.assign_positions_to_requests!(@requests.reverse.map(&:id))

        expected = Hash[@requests.reverse.each_with_index.map { |request,index| [ request.id, index+1 ] }]
        actual   = Hash[@batch.batch_requests.map { |batch_request| [ batch_request.request_id, batch_request.position ] }]
        assert_equal(expected, actual, "Positions of requests do not match")
      end
    end

    context '#shift_item_positions' do
      setup do
        @requests.each { |r| r.update_attributes!(:asset => nil) }
      end

      should 'move the requests that are at, and after, the position by the number and have no asset' do
        @batch.shift_item_positions(5, 2)

        positions = [ 1, 2, 3, 4, 7, 8, 9, 10, 11, 12 ]
        expected  = Hash[@requests.each_with_index.map { |request,index| [ request.id, positions[index] ] }]
        actual    = Hash[@batch.batch_requests.map { |batch_request| [ batch_request.request_id, batch_request.position ] }]
        assert_equal(expected, actual, "Positions of requests do not match")
      end
    end

  end

  context "when batch is created" do
    setup do
      @request1 = @pipeline.request_types.last.create!(:asset => Factory(:sample_tube), :target_asset => Factory(:empty_library_tube))
      @request2 = @pipeline.request_types.last.create!(:asset => Factory(:sample_tube), :target_asset => Factory(:empty_library_tube))

      @batch = @pipeline.batches.create!(:requests => [ @request1, @request2 ])
    end
    should "be able to call start_requests" do
      assert_nothing_raised do
        @batch.start_requests
      end
    end

    should "have initially have a pending status for batch requests" do
      assert_equal :pending, @batch.requests.first.aasm_current_state
      @batch.start!(Factory(:user))
      assert_equal :started, @batch.aasm_current_state
      assert_equal :started, @batch.requests(true).first.aasm_current_state
    end

    context "#remove_request_ids" do
      context "with 2 requests" do
        context "where 1 needs to be removed" do
          setup do
            @batch_requests_count = @batch.requests.count
            @batch.remove_request_ids([ @request2.id])
          end
          should "leave 2 requests behind" do
            assert_not_nil @batch.requests.find(@request2)
            assert_not_nil @batch.requests.find(@request1)
            assert_equal @batch_requests_count, @batch.requests.count
          end
        end
      end
    end

    context "create requests" do
      setup do
        @requests    = (1..4).map { |_| Factory(:request, :request_type => @pipeline.request_types.last) }
        @request_ids = @requests.map { |r| Request.new_proxy(r.id) }
        @batch       = @pipeline.batches.create!(:requests => @requests)
      end

      should_change("Asset.count", :by => 8) { Asset.count }

      should "not have same asset name" do
        assert_not_equal Asset.first.name, Asset.last.name
      end
    end

  end

  context "batch #has_event(event_name)" do
    setup do
      @batch = @pipeline.batches.create!
      @batch.start!(Factory(:user))

      @lab_event = LabEvent.new
    end
    context "when a batch is not associated with any events, it" do
      should "return false." do
        assert_equal false, @batch.has_event("Tube layout verified"),
          "#has_event should return false if an event is not found"
      end
    end
    context "when a batch has a LabEvent" do
      setup do
        @lab_event.description = nil
        @batch.lab_events << @lab_event
      end
      should "it should only return if the description is set" do
        assert_equal false, @batch.has_event("Tube layout verified")
        @lab_event.description ="Tube layout verified"
        @batch.lab_events << @lab_event
        assert_equal true, @batch.has_event("Tube layout verified")
      end
    end
  end


  context "#requests_by_study" do
    setup do
      @pipeline.workflow.update_attributes!(:locale => 'Internal')
      @batch = @pipeline.batches.create!

      @study1 = Factory :study
    end

    context "with no requests" do
      should "return an empty array" do
        assert @batch.requests.for_studies(@study1).empty?
      end
    end

    context "with 1 request" do
      setup do
        @study2 = Factory :study
        @request1 = @batch.requests.create!(:request_type => @pipeline.request_types.last, :study => @study1)
      end

      should "return correct studies" do
        assert @batch.requests.for_studies(@study1).include?(@request1)
        assert @batch.requests.for_studies(@study2).all.empty?
      end

      should "be #externally_released?" do
        @batch.update_attributes!(:state => 'released')
        assert_equal @batch.externally_released?, true
      end
    end

    context "with 2 requests from different studies" do
      setup do
        @study2 = Factory :study
        @study3 = Factory :study
        @request1 = @batch.requests.create!(:request_type => @pipeline.request_types.last, :study => @study1)
        @request2 = @batch.requests.create!(:request_type => @pipeline.request_types.last, :study => @study2)
      end

      should "return correct studies" do
        assert @batch.requests.for_studies(@study1).include?(@request1)
        assert @batch.requests.for_studies(@study2).include?(@request2)
        assert @batch.requests.for_studies(@study3).all.empty?
      end
    end
  end


  context "#plate_ids_in_study" do
    setup do
      @batch = @pipeline.batches.create!
      @study1 = Factory :study
    end

    context "with no requests" do
      should "not return plate ids" do
        assert @batch.plate_ids_in_study(@study1).empty?
      end

      should "be #internally_released?" do
        @pipeline.workflow.update_attributes!(:locale => 'External')
        @batch.update_attributes!(:state => 'released')
        assert_equal @batch.internally_released?, true
      end
    end

    context "with 2 request on a different plates" do
      setup do
        @study2 = Factory :study
        @plate1 = Factory :plate
        @well1 = Factory :well, :plate => @plate1

        @plate2 = Factory :plate
        @well2 = Factory :well, :plate => @plate2

        @batch.requests = [
          @pipeline.request_types.last.create!(:study => @study1, :asset => @well1),
          @pipeline.request_types.last.create!(:study => @study1, :asset => @well2)
        ]
      end
      should "return 1 plate id where they are in given study" do
        assert 2, @batch.plate_ids_in_study(@study1).size
        assert @batch.plate_ids_in_study(@study1).include?(@plate1.id)
        assert @batch.plate_ids_in_study(@study1).include?(@plate2.id)
      end
      should "not return a plate id where they are not in the given study" do
        assert ! @batch.plate_ids_in_study(@study2).include?(@plate1.id)
      end
    end
  end


  context "Batch" do
    should_belong_to :user, :pipeline, :assignee
    should_have_many :failures, :lab_events, :requests
    should_have_instance_methods :shift_item_positions, :assigned_user, :start, :fail, :workflow, :started?, :released?, :externally_released?, :internally_released?, :qc_state
    should_have_instance_methods :submit_to_qc_queue

    setup do
      @pipeline_next = Factory :pipeline, :name => 'Next pipeline'
      @pipeline      = Factory :pipeline, :name => 'Pipeline for BatchTest', :automated => false, :next_pipeline_id => @pipeline_next.id, :asset_type => "LibraryTube"
      @pipeline_qc   = Factory :pipeline, :name => 'quality control', :automated => true, :next_pipeline_id => @pipeline_next.id
    end

    context "create requests" do
      setup do
        @requests = (1..4).map { |_| Factory(:request, :request_type => @pipeline.request_types.last) }
        @request_ids = @requests.map { |r| Request.new_proxy(r.id) }
        @batch = @pipeline.batches.create!(:requests => @requests)
      end

      should_change("Asset.count", :by => 12) { Asset.count }

      should "not have same asset name" do
        assert_not_equal Asset.first.name, Asset.last.name
      end

      should "have the good number of request associated" do
        assert_equal @request_ids.size , @batch.batch_requests.count
      end

      should "have request position corresponding to the request creation order" do
        @batch.batch_requests.each do |br|
          assert_equal @request_ids[br.position-1].id ,  br.request_id
        end
      end
    end

    context "when a batch is failed" do
      setup do
        # send_fail_event will be used once since only one request is not a resource /@request1
#        EventSender.expects(:send_fail_event).returns(true).times(1)
        EventSender.stubs(:send_fail_event).returns(true)
        @control  = Factory :sample_tube, :resource => true

        @batch = @pipeline.batches.create!
        @request1, @request2 = @batch.requests = [
          @pipeline.request_types.last.create!,
          @pipeline.request_types.last.create!(:asset => @control)
        ]

        @reason = "PCR not enough"
        @comment = "Hey! sing Are we human?"
      end

      should "return true if batch has failed and have 2 requests" do
        @batch.fail(@reason, @comment)
        assert_equal @batch.production_state, "fail"
        assert @batch.failed?
        assert_equal @batch.request_count, 2
      end

      context "create failures" do
        setup do
          @batch.fail(@reason, @comment)
        end

        should "have matching batch requests" do
          assert_equal @request1.id, @batch.requests.first.id
          assert_equal @request2.id, @batch.requests.last.id
        end

        should_change("@batch.failures.count", :from => 0, :to => 1) { @batch.failures.count }
        should_change("@batch.production_state", :from => nil, :to => "fail") { @batch.production_state }
      end
    end

    context "when specific requests in a batch are failing" do
      setup do
        @batch = @pipeline.batches.create!
        @request1, @request2 = @batch.requests = [
          @pipeline.request_types.last.create!,
          @pipeline.request_types.last.create!
        ]

        @reason = "PCR not enough"
        @comment = "Hey! Are we human?"
      end

      context "fail requests" do
        setup do
          EventSender.expects(:send_fail_event).returns(true).times(1)
          @requests = { "#{@request1.id}"=>"on" }
          @batch.fail_batch_items(@requests, @reason, @comment)
        end

        should "fail requested requests"

        should "not fail not requested requests"

        should "not fail the batch"

        should "create failures on failed requests"
      end

      context "control request" do
        setup do
          EventSender.expects(:send_fail_event).returns(true).times(1)
          @asset = Factory :sample_tube, :resource => 1
          @request3 = Factory :request, :batches => [@batch], :id => 789, :asset => @asset
          @requests = { "#{@request1.id}"=>"on", "control"=>"on" }
          @batch.fail_batch_items(@requests, @reason, @comment)
          assert_equal @request3, @batch.control
        end

        should "fail control request"
      end

      should "not fail requests if value passed is not set to ON" do
        @requests = { "#{@request1.id}"=>"blue" }
        @batch.fail_batch_items(@requests, @reason, @comment)
        assert_equal 0, @batch.requests.first.failures.size
      end

      context "fail the batch" do
        setup do
          EventSender.expects(:send_fail_event).returns(true)
          @requests = { "#{@request1.id}"=>"on", "#{@request2.id}"=>"on" }
          @batch.fail_batch_items(@requests, @reason, @comment)
        end

        should "if all the requests within the batch are failing, fail the batch too"
        should "change @batch.failures.count, :from => 0, :to => 1"
      end
    end

    context "#public methods" do
      setup do
        @asset1 = Factory :sample_tube, :barcode => "123456"
        @asset2 = Factory :sample_tube, :barcode => "654321"

        @request1 = @pipeline.request_types.last.create!(:asset => @asset1)
        @request2 = @pipeline.request_types.last.create!(:asset => @asset2)

        @batch = @pipeline.batches.create!
        @batch.batch_requests.create!(:request => @request1, :position => 2)
        @batch.batch_requests.create!(:request => @request2, :position => 1)
        @batch.reload
      end

      should "return ordered requests" do
        v = @batch.ordered_requests
        assert_equal @request2, v[0]
        assert_equal @request1, v[1]
      end

      should "return true if the tubes are scanned in in the correct order" do
        number_of_batch_events = @batch.lab_events.size
        assert @batch.verify_tube_layout({"1" => "654321", "2" => "123456"})
        assert_equal number_of_batch_events + 1, @batch.lab_events.size
      end

      should "return false and add errors to the batch if the tubes are not in the correct order" do
        number_of_batch_events = @batch.lab_events.size
        assert ! @batch.verify_tube_layout({"1" => "123456", "2" => "654321"})
        assert ! @batch.errors.empty?
        assert_equal number_of_batch_events, @batch.lab_events.size
      end

      should "reorder requests by increasing request.position if it's > 3" do
        Factory :batch_request, :batch => @batch, :position => 6
        Factory :batch_request, :batch => @batch, :position => 8
        v = @batch.shift_item_positions(4,1)
        # assert_equal 3, v[2].id # make sure that requests are the same
        # assert_equal 4, v[3].id # make sure that requests are the same
        assert_equal 9, v[3].position(@batch) # make sure that requests.position was increased properly
        assert_equal 7, v[2].position(@batch) # make sure that requests.position was increased properly
      end

      should "return empty assigned user" do
        assert "", @batch.assigned_user
      end

      should "return user login" do
        @user = Factory :user
        @batch.assignee_id = @user.id
        assert "lg1", @batch.assigned_user
      end

      context 'with control' do
        setup do
          @control = Factory :sample_tube, :resource => true
          @request = @pipeline.request_types.last.create!(:asset => @control)
          @batch.batch_requests.create!(:request => @request, :position => 3)
        end

        should "return true a request has resource" do
          assert @batch.has_control?
        end

        should "return the first request with resource" do
          assert_equal @request, @batch.control
        end
      end

      should "return true if self has item_limit" do
        assert @batch.has_limit?
      end

      context "underrun" do
        setup do
          @pipeline.workflow.update_attributes!(:item_limit => 4)
        end

        should "return POSITIVE difference between batch.request_limit and batch.request_count" do
          assert_equal 2, @batch.underrun
        end

        should "return NEGATIVE difference between batch.request_limit and batch.request_count" do
          @batch.batch_requests.create!(:request => @pipeline.request_types.last.create!, :position => 3)
          @batch.batch_requests.create!(:request => @pipeline.request_types.last.create!, :position => 4)
          @batch.batch_requests.create!(:request => @pipeline.request_types.last.create!, :position => 5)
          assert_equal(-1, @batch.underrun)
        end
      end

      should "return 0 if batch has no request_limit set" do
        @pipeline.workflow.update_attributes!(:item_limit => nil)
        assert_equal 0, @batch.underrun
      end

      # should "return true if batch belongs to multiplexing" do
      #   Factory :cross_ref, :request => @request1, :kind => "sample_pool"
      #   assert @batch.multiplexed?
      # end
      #
      # should "return false if batch DOES NOT belong to multiplexing" do
      #   assert ! @batch.multiplexed?
      # end
    end

    context "#QC related" do
      context "#qc_criteria_received" do
        setup do
          @batch = @pipeline.batches.create!
        end

        should "have pending as qc_state until flag is set" do
          assert_equal 'qc_pending', @batch.qc_state
          @batch.qc_state = "qc_manual_in_progress"
          @batch.qc_complete
          assert_equal "qc_completed", @batch.qc_state
        end
      end

      context "#qc_evaluation_update" do
        setup do
          @batch = @pipeline.batches.create!(:qc_state => 'qc_pending')

          @library1 = Factory :sample_tube
          @library2 = Factory :sample_tube
          @batch.batch_requests.create!(
            :request  => @pipeline.request_types.last.create!(:asset => @library1, :target_asset => Factory(:library_tube)),
            :position => 1
          )
          @batch.batch_requests.create!(
            :request  => @pipeline.request_types.last.create!(:asset => @library2, :target_asset => Factory(:library_tube)),
            :position => 2
          )

          @task = Factory :task, :workflow => @pipeline.workflow
        end

        context "when evaluations tag contains 1 evaluation" do
          setup do
            @evaluation = {
              "result"=>"pass",
              "checks"=>{
                "check"=>{
                  "results"=>"Some free form data (no html please)",
                  "criteria"=>{
                    "criterion"=>[
                      {"value"=>"Greater than 80mb", "key"=>"yield"},
                      {"value"=>"Greater than Q20", "key"=>"count"}
                    ]
                  },
                  "data_source"=>"/somewhere.fastq",
                  "links"=>{
                    "link"=>{
                      "href"=>"http://example.com/some_interesting_image_or_table",
                      "label"=>"display text for hyperlink"
                    }
                  },
                  "comment"=>"All good",
                  "pass"=>"true"
                }
              },
              "check"      => "Auto QC",
              "identifier" => @batch.id,
              "location"   => 1
            }
            @evaluations = [ @evaluation ]
          end

          context 'checking stuff' do
            setup do
              @rc = Batch.qc_evaluations_update({ 'evaluation' => @evaluation })
            end

            should_change('LabEvent.count', :by => 2) { LabEvent.count }

            should 'return no errors' do
              assert_equal({ 'evaluation' => @evaluation }, @rc)
            end

            should "event should include passed params" do
              @event = LabEvent.last
              assert_equal @event.description,       @evaluations.last["check"]
              assert_equal @event.descriptor_fields, @evaluations.last["checks"]["check"].keys
              assert_equal @event.descriptors.size,  @evaluations.last["checks"]["check"].size
            end

            should "update batches pipeline to manual qc_pipeline" do
              assert_equal @pipeline_next.id, Batch.find(@batch).qc_pipeline_id
            end
          end

          [ 'qc_pending', 'qc_submitted', 'qc_manual' ].each do |initial_state|
            should "changing state from #{initial_state}" do
              @batch.update_attributes!(:qc_state => initial_state)
              Batch.qc_evaluations_update({ 'evaluation' => @evaluation })
              assert_equal('qc_manual', Batch.find(@batch).qc_state)
            end
          end
        end

        context "when evaluations tag contains more than 1 evaluation" do
          setup do
            @info = {"evaluation"=>[{"result"=>"pass", "checks"=>{"check"=>[{"results"=>"Some free form data (no html please)", "criteria"=>{"criterion"=>[{"value"=>"Greater than 80mb", "key"=>"yield"}, {"value"=>"Greater than Q20", "key"=>"count"}]}, "data_source"=>"/somewhere.fastq", "links"=>{"link"=>{"href"=>"http://example.com/some_interesting_image_or_table", "label"=>"display text for hyperlink"}}, "comment"=>"All good", "pass"=>"true"}, {"results"=>"Some free form data (no html please)", "criteria"=>{"criterion"=>[{"value"=>"Greater than 80mb", "key"=>"yield"}, {"value"=>"Greater than Q20", "key"=>"count"}]}, "data_source"=>"/somewhere.fastq", "links"=>{"link"=>{"href"=>"http://example.com/some_interesting_image_or_table", "label"=>"display text for hyperlink"}}, "comment"=>"All good", "pass"=>"true"}]}, "check"=>"Auto QC", "identifier"=>@batch.id, "location"=>1}, {"result"=>"fail", "checks"=>{"check"=>{"results"=>"Some free form data (no html please)", "criteria"=>{"criterion"=>[{"value"=>"Greater than 80mb", "key"=>"yield"}, {"value"=>"Greater than Q20", "key"=>"count"}]}, "data_source"=>"/somewhere.fastq", "links"=>{"link"=>{"href"=>"http://example.com/some_interesting_image_or_table", "label"=>"display text for hyperlink"}}, "comment"=>"All good", "pass"=>"true"}}, "check"=>"Auto QC", "identifier"=>@batch.id, "location"=>2}]}
            @events_count = LabEvent.count
            @requests_count = Request.count
          end

          should "return no errors if successful" do
            assert true, Batch.qc_evaluations_update(@info)
          end

          should "create an event using passed params" do
            assert_equal 0, @events_count
            Batch.qc_evaluations_update(@info)
            assert_equal 5, LabEvent.count
          end

          should "event should include passed params" do
            Batch.qc_evaluations_update(@info)
            @event = LabEvent.last
            assert_equal @event.description, @info["evaluation"].last["check"]
            assert_equal @event.descriptor_fields, @info["evaluation"].last["checks"]["check"].keys
            assert_equal @event.descriptors.size, @info["evaluation"].last["checks"]["check"].size
          end

          should "update qc_state on an request" do
            batch_events_size = @batch.lab_events.size
            Batch.qc_evaluations_update(@info)
            assert_equal batch_events_size + @info["evaluation"].size, Batch.find(@batch.id).lab_events.size
            # assert_equal @info["evaluation"].first["result"], @batch.batch_requests.find_by_position(@info["evaluation"].first["location"]).request.target_asset.qc_state
          end
        end
      end
    end

    context "#reset!" do
      setup do
        @batch = @pipeline.batches.create!
        @started_request   = @pipeline.request_types.last.create!(:state => 'pending',   :target_asset => Factory(:sample_tube))
        @cancelled_request = @pipeline.request_types.last.create!(:state => 'cancelled', :target_asset => Factory(:sample_tube))
        @batch.requests << @started_request << @cancelled_request

        @batch.expects(:destroy)    # Always gets destroyed
      end

      # Separate context because we need to setup the DB first and we cannot check the changes made.
      context 'checking DB changes' do
        setup do
          @batch.reset!(@user)
        end

        should_change('BatchRequest.count', :by => -2) { BatchRequest.count }
        should_change('Asset.count', :by => -2) { Asset.count }
      end
    end

    context "#qc_previous_state!" do
      setup do
        @user = Factory :user
        @batch = @pipeline.batches.create!
        @batch.update_attributes!(:qc_state => 'qc_completed')
      end
      should "move batch to previous qc state" do
        assert_equal"qc_completed", @batch.qc_state
        @batch.qc_previous_state!(@user)
        assert_equal "qc_manual_in_progress", @batch.qc_state
        @batch.qc_previous_state!(@user)
        assert_equal "qc_manual", @batch.qc_state
      end
    end

    context "#swap" do
      # We must test swapping requests at different and same positions, as well as ones which would clash if not adjusted
      [
        [ 3, 4 ],
        [ 4, 4 ],
        [ 2, 1 ]
      ].each do |left_position, right_position|
        context "when swapping #{left_position} and #{right_position}" do
          setup do
            # Create a batch with a couple of requests positioned appropriately
            @left_batch            = Factory :batch, :pipeline => @pipeline
            @original_left_request = Factory :batch_request, :batch_id => @left_batch.id, :position => left_position
            Factory :batch_request, :batch_id => @left_batch.id, :position => 1

            # Now create another batch that we'll swap the requests between
            @right_batch            = Factory :batch, :pipeline => @pipeline
            @original_right_request = Factory :batch_request, :batch_id => @right_batch.id, :position => right_position
            Factory :batch_request, :batch_id => @right_batch.id, :position => 2

            @user = Factory :user
          end

          should "swap lanes given 2 batches and swap requests." do
            assert(
              @left_batch.swap(
                @user, {
                  "batch_1" => {"id" => @left_batch.id.to_s,  "lane" => left_position.to_s },
                  "batch_2" => {"id" => @right_batch.id.to_s, "lane" => right_position.to_s }
                }
             )
            )

            # The two requests should have been swapped
            assert_equal(@original_right_request.request, @left_batch.batch_requests.at_position(left_position).first.request)
            assert_equal(@original_left_request.request,  @right_batch.batch_requests.at_position(right_position).first.request)
          end
        end
      end
    end

    context "#detach_request" do
      setup do
        @library_prep_pipeline = Factory :pipeline, :name => "Library Prep Pipeline"
        @pe_pipleine = Factory :pipeline, :name => "PE pipeline"
        @lib_prep_batch = Factory :batch, :pipeline => @library_prep_pipeline
        @lib_prep_request = Factory :request, :state => "started"
        @pe_seq_request = Factory :request, :state => "pending"
        @lib_prep_batch.requests << @lib_prep_request
        @sample_tube = Factory :sample_tube, :name => "sample tube 1"
        @library_tube = Factory :library_tube, :name => "lib tube 1"
        @number_of_assets = Asset.count
        @lib_prep_request.asset = @sample_tube
        @lib_prep_request.target_asset = @library_tube
        @lib_prep_request.save
        @pe_seq_request.asset = @library_tube
        @pe_seq_request.save
      end

      context "detaching" do
        setup do
          @lib_prep_batch.detach_request(@lib_prep_request)
        end

        context "from the input side of the batch" do
          setup do
            @lib_prep_request.reload
          end

          should "remove the target asset from the request and remove the request from the batch" do
            assert @lib_prep_request.target_asset.nil?
            assert @lib_prep_batch.requests.include?(@lib_prep_request)
          end
        end

        context "from the output side of the batch" do
          setup do
            @pe_seq_request.reload
          end

          should "remove the asset from the request" do
            assert @pe_seq_request.asset.nil?
          end
        end
      end

      should "not raise any exceptions if the request does not have a target asset" do
        @lib_prep_request.target_asset = nil
        @lib_prep_request.save

        assert_nothing_raised do
          @lib_prep_batch.detach_request(@lib_prep_request)
        end
      end

      should "not raise any exceptions if the request does not have an asset" do
        @pe_seq_request.asset = nil
        @pe_seq_request.save

        assert_nothing_raised do
          @lib_prep_batch.detach_request(@lib_prep_request)
        end
      end
    end

    context "#last_completed_task" do
      setup do
        @library_prep_pipeline = Factory :pipeline, :name => "Library Prep Pipeline"
        @task1 = Factory :task, :workflow => @library_prep_pipeline.workflow, :name => "Task 1", :sorted => 0
        @task2 = Factory :task, :workflow => @library_prep_pipeline.workflow, :name => "Task 2", :sorted => 1
        @task3 = Factory :task, :workflow => @library_prep_pipeline.workflow, :name => "Task 3", :sorted => 2

        @batch = @library_prep_pipeline.batches.create!(:state => 'started')
        @batch.requests << @library_prep_pipeline.request_types.last.create!(:state => 'started')
        @batch.requests << @library_prep_pipeline.request_types.last.create!(:state => 'started')

        @desc1 = mock("Descriptor")
        @desc1.stubs(:name).returns("task_id")
        @desc1.stubs(:value).returns("#{@task1.id}")
        @desc1.stubs(:task_id).returns(nil)

        @desc2 = mock("Descriptor")
        @desc2.stubs(:name).returns("task_id")
        @desc2.stubs(:value).returns("#{@task1.id}")
        @desc2.stubs(:task_id).returns(nil)

        @event1 = mock("LabEvent1")
        @event1.stubs(:description).returns("Complete")
        @event1.stubs(:descriptors).returns([@desc1, @desc2])

        @desc3 = mock("Descriptor")
        @desc3.stubs(:name).returns("task_id")
        @desc3.stubs(:value).returns("#{@task2.id}")
        @desc3.stubs(:task_id).returns(nil)

        @desc4 = mock("Descriptor")
        @desc4.stubs(:name).returns("task_id")
        @desc4.stubs(:value).returns("#{@task2.id}")
        @desc4.stubs(:task_id).returns(nil)

        @event2 = mock("LabEvent2")
        @event2.stubs(:description).returns("Complete")
        @event2.stubs(:descriptors).returns([@desc3, @desc4])

        @batch.stubs(:lab_events).returns([@event1, @event2])
      end

      should "return the last task the batch completed" do
        assert ! @batch.events_for_completed_tasks.empty?
        assert ! @batch.tasks_for_completed_task_events(@batch.events_for_completed_tasks).empty?
        assert_equal 2, @batch.lab_events.size
        assert_equal @task2, @batch.last_completed_task
      end
    end

    context "#output_plate_purpose" do
      setup do
        @batch = @pipeline.batches.create!
      end

      context "where no output plates are set," do
        setup do
          @batch.stubs(:output_plates).returns([nil])
        end

        should "return nil" do
          assert_nil @batch.output_plate_purpose
        end
      end


      context "where at least 1 output plate is set," do
        setup do
          @plate = mock("Plate")
          @plate_purpose = 'A_PLATE_PURPOSE'
          @plate.stubs(:plate_purpose).returns(@plate_purpose)
          @batch.stubs(:output_plates).returns([@plate])
        end

        should "return the plate_purpose of the first output plate associated with @batch, currently assumed to the same for all output plates." do
          assert_equal @plate_purpose, @batch.output_plate_purpose
        end
      end
    end

    context "#set_output_plate_purpose" do
      setup do
        @batch = @pipeline.batches.create!
        @plate_purpose = 'A_PLATE_PURPOSE_INSTANCE'
        @output_plate = mock("Plate")
      end

      context "with a set of output plates," do
        setup do
          @output_plate.expects(:plate_purpose=).with(@plate_purpose)
          @output_plate.expects(:save!)
          @batch.stubs(:output_plates).returns([@output_plate])
          @return_value = @batch.set_output_plate_purpose(@plate_purpose)
        end

        should "set the plate_purpose of associated output plates to @plate_purpose and return true" do
          assert_equal true, @return_value
        end
      end

      context "when no output plates are defined," do
        setup do
          @output_plate.expects(:plate_purpose=).never
          @batch.expects(:output_plates).returns([])
        end

        should "should do no assignments but raise a RuntimeError" do
          assert_raise(RuntimeError) {
            @batch.set_output_plate_purpose(@plate_purpose)
          }
        end
      end
    end
  end

  context "completing a batch" do
    setup do
      @batch, @user = Factory(:batch), Factory(:user)
      @batch.start!(@user)
    end

    should "check that with the pipeline that the batch is valid" do
      @batch.pipeline.expects(:validation_of_batch_for_completion).with(@batch)
      @batch.complete!(@user)
    end
  end
end
