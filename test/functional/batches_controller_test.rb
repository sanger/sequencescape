# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

require 'test_helper'
require 'batches_controller'

class BatchesControllerTest < ActionController::TestCase
  context 'BatchesController' do
    setup do
      @controller = BatchesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end
    should_require_login

    context 'with a false user for npg' do
      setup do
        session[:current_user] = :false
      end

      context 'NPG xml view' do
        setup do
          pipeline = Pipeline.find_by!(name: 'Cluster formation PE (no controls)')

          @study, @project = FactoryGirl.create(:study), FactoryGirl.create(:project)
          @sample = FactoryGirl.create :sample
          @submission = FactoryGirl.create :submission_without_order, priority: 3

          @library = FactoryGirl.create(:empty_library_tube).tap do |library_tube|
            library_tube.aliquots.create!(sample: @sample, project: @project, study: @study, library: library_tube, library_type: 'Standard')
          end
          @lane = FactoryGirl.create(:empty_lane, qc_state: 'failed')
          @request_one = pipeline.request_types.first.create!(
            asset: @library, target_asset: @lane,
            project: @project, study: @study,
            submission: @submission,
            request_metadata_attributes: { fragment_size_required_from: 100, fragment_size_required_to: 200, read_length: 76 }
          )

          batch = FactoryGirl.create :batch, pipeline: pipeline
          batch.batch_requests.create!(request: @request_one, position: 1)
          batch.reload
          batch.start!(create(:user))

          get :show, id: batch.id, format: :xml
        end

        should 'Respond with xml' do
          assert_equal 'application/xml', @response.content_type
        end

        should 'have api version attribute on root object' do
          assert_response :success
          assert_select "lane[position='1'][id='#{@lane.id}'][priority='3']"
          assert_select "library[request_id='#{@request_one.id}'][qc_state='fail']"
        end

        should 'expose the library information correctly' do
          assert_select "sample[library_id='#{@library.id}'][library_name='#{@library.name}'][library_type='Standard']"
        end
      end
    end

    context 'with a user logged in' do
      setup do
        @user = create :user
        session[:user] = @user.id
      end

      context 'with a few batches' do
        setup do
          @batch_one = create :batch
          @batch_two = create :batch
        end

        should '#index' do
          get :index
          assert_response :success
          assert assigns(:batches)
        end

        should '#show' do
          get :show, id: @batch_one.id
          assert_response :success
          assert_equal @batch_one, assigns(:batch)
        end

        should '#edit' do
          get :edit, id: @batch_one
          assert_response :success
          assert_equal @batch_one, assigns(:batch)
        end
      end

      context 'with a cherrypick pipeline' do
        setup do
          @pipeline = create :cherrypick_pipeline
          @requests = create_list(:cherrypick_request_for_pipeline, 2, request_type: @pipeline.request_types.first)
          @selected_request = @requests.first
          @submission = @selected_request.submission || raise('No Sub')
          @plate      = @selected_request.asset.plate || raise('No plate')
        end

        should '#create' do
          post :create, id: @pipeline.id,
                        utf8: '✓',
                        action_on_requests: 'create_batch',
                        request_group: { "#{@plate.id}, #{@submission.id}" => '1' },
                        "request_group_#{@plate.id}_#{@submission.id}_size": '1',
                        commit: 'Submit'
        end
      end

      context 'actions' do
        setup do
          @pipeline_next = create :pipeline, name: 'Next pipeline'
          @pipeline = create :pipeline, name: 'New Pipeline', automated: false, next_pipeline_id: @pipeline_next.id
          @pipeline_qc_manual = create :pipeline, name: 'Manual quality control', automated: false, next_pipeline_id: @pipeline_next.id
          @pipeline_qc = create :pipeline, name: 'quality control', automated: true, next_pipeline_id: @pipeline_qc_manual.id

          @ws = @pipeline.workflow # :name => 'A New workflow', :item_limit => 2
          @ws_two = @pipeline_qc.workflow # :name => 'Another workflow', :item_limit => 2
          @ws_two.update_attributes!(locale: 'External')

          @batch_one = create(:batch, pipeline: @pipeline)
          @batch_two = create(:batch, pipeline: @pipeline_qc)

          @sample   = create :sample_tube
          @library1 = create :empty_library_tube, location: @pipeline.location
          @library1.parents << @sample
          @library2 = create :empty_library_tube, location: @pipeline.location
          @library2.parents << @sample

          @target_one = create(:sample_tube)
          @target_two = create(:sample_tube)

          # TODO: add a control_request_type to pipeline...
          @request_one = @pipeline.request_types.first.create!(asset: @library1, target_asset: @target_one, project: create(:project))
          @batch_one.batch_requests.create!(request: @request_one, position: 1)
          @request_two = @pipeline.request_types.first.create!(asset: @library2, target_asset: @target_two, project: create(:project))
          @batch_one.batch_requests.create!(request: @request_two, position: 2)
          @batch_one.reload
        end

        context '#edit' do
          context 'with control' do
            setup do
              @cn = FactoryGirl.create :control, name: 'Control 1', item_id: 2, pipeline: @pipeline
              @pipeline.controls << @cn
            end
            should '#add control' do
              get :add_control, id: @batch_one, control: { id: @cn.id }
            end
            should '#create_training_batchl' do
              get :create_training_batch, id: @batch_one, control: { id: @cn.id }
            end
          end
        end

        should '#update' do
          @pipeline_user = create :pipeline_admin, login: 'ur1', first_name: 'Ursula', last_name: 'Robinson'
          put :update, id: @batch_one.id, batch: { assignee_id: @pipeline_user.id }
          assert_redirected_to batch_path(assigns(:batch))
          assert_equal assigns(:batch).assignee, @pipeline_user
          assert_includes flash[:notice], 'Assigned to Ursula Robinson (ur1)'
        end

        should 'redirect on update without param' do
          put :update, id: @batch_one.id, batch: { id: 'bad id' }
          assert_response :redirect
        end

        context '#create' do
          setup do
            @old_count = Batch.count

            @request_three = @pipeline.request_types.first.create!(asset: @library1, project: FactoryGirl.create(:project))
            @request_four  = @pipeline.request_types.first.create!(asset: @library2, project: FactoryGirl.create(:project))
          end

          context 'redirect to #show new batch' do
            setup do
              post :create, id: @pipeline.id, request: { @request_three.id => '0', @request_four.id => '1' }
            end

            should 'create_batch  with no controls' do
              assert_equal @old_count + 1, Batch.count
              assert_redirected_to batch_path(assigns(:batch))
            end
          end

          context 'redirect to action #control' do
            setup do
              @cn = FactoryGirl.create :control, name: 'Control 1', item_id: 2, pipeline: @pipeline
              @pipeline.controls << @cn
              post :create, id: @pipeline.id, request: { @request_three.id => '0', @request_four.id => '1' }
            end

            should 'if pipeline has controls' do
              assert_equal @old_count + 1, Batch.count
              assert_equal 'Batch created - now add a control', flash[:notice]
              assert_redirected_to controller: 'batches', action: 'control', id: Batch.last.id
            end
          end

          context 'create batch and assign requests' do
            setup do
              @old_count = Batch.count
              post :create, id: @pipeline.id, request: { @request_three.id => '1', @request_four.id => '1' }
              @batch = Batch.last
            end

            should 'create assets and change batch requests' do
              assert_equal @old_count + 1, Batch.count
              assert_equal 2, @batch.request_count
              assert @batch.requests.first.asset
              assert @batch.requests.last.asset
            end
          end
        end

        context '#released' do
          should 'return all released batches if passed params' do
            get :released, id: @pipeline.id
            assert_response :success
          end
        end

        context '#fail' do
          should 'render fail reasons when internal' do
            get :fail, id: @batch_one.id
            assert @batch_one.workflow.source_is_internal?
            assert_response :success
            assert assigns(:fail_reasons)
          end

          should 'render fail reasons when external' do
            get :fail, id: @batch_two.id
            assert !@batch_two.workflow.source_is_internal?
            assert_response :success
            assert assigns(:fail_reasons)
          end
        end

        context '#fail_items' do
          setup do
            # We need to ensure the batch is started before we fail it.
            @batch_one.start!(create(:user))
          end

          context 'posting without a failure reason' do
            setup do
              post :fail_items, id: @batch_one.id, failure: { reason: '', comment: '' }
            end
            should 'not allow failing a batch/items without specifying a reason and set the flash' do
              assert_includes flash[:error], 'Please specify a failure reason for this batch'
              assert_redirected_to action: :fail, id: @batch_one.id
            end
          end

          context 'posting with a failure reason' do
            context 'individual items' do
              setup do
                EventSender.expects(:send_fail_event).returns(true).times(1)
                post :fail_items, id: @batch_one.id,
                                  failure: { reason: 'PCR not completed', comment: '' },
                                  requested_fail: { (@request_one.id).to_s => 'on' }
              end
              should 'create a failure on each item in this batch and have two items related' do
                assert_equal 0, @batch_one.failures.size
                assert_equal 2, @batch_one.size

                # First item
                assert_equal 1, @batch_one.requests.first.failures.size
                assert_equal 'PCR not completed', @batch_one.requests.first.failures.first.reason
                # Second item
                assert_equal 0, @batch_one.requests.last.failures.size
              end
            end
          end
        end
      end
    end

    context 'Find by barcode (found)' do
      setup do
        @controller.stubs(:current_user).returns(@admin)
        @batch = FactoryGirl.create :batch
        request = FactoryGirl.create :request
        @batch.requests << request
        r = @batch.requests.first
        @e = r.lab_events.create(description: 'Cluster generation')
        @e.add_descriptor Descriptor.new(name: 'Chip Barcode', value: 'Chip Barcode: 62c7gaaxx')
        @e.batch_id = @batch.id
        @e.save
        get :find_batch_by_barcode, id: '62c7gaaxx', format: :xml
      end
      should 'show batch' do
        assert_response :success
        assert_equal 'application/xml', @response.content_type
        assert_template 'batches/show'
      end
    end

    context 'Find by barcode (not found)' do
      setup do
        @controller.stubs(:current_user).returns(@admin)
        get :find_batch_by_barcode, id: '62c7axx', format: :xml
      end
      should 'show error' do
        # this is the wrong response!
        assert_response :success
        assert_equal 'application/xml', @response.content_type
        assert_template 'batches/batch_error'
      end
    end

    context 'Send print requests' do
      attr_reader :barcode_printer

      setup do
        @user = create :user
        @controller.stubs(:current_user).returns(@user)
        @barcode_printer = create :barcode_printer
        LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
      end

      should '#print_plate_barcodes should send print request' do
        study = create :study
        project = create :project
        asset = create :empty_sample_tube
        order_role = Order::OrderRole.new role: 'test'

        order = create :order, order_role: order_role, study: study, assets: [asset], project: project
        request = create :well_request, asset: (create :well_with_sample_and_plate), target_asset: (create :well_with_sample_and_plate), order: order

        @batch = create :batch
        @batch.requests << request

        RestClient.expects(:post)

        post :print_plate_barcodes, printer: barcode_printer.name, count: '3', printable: { (@batch.output_plates.first.barcode).to_s => 'on' }, batch_id: (@batch.id).to_s
      end

      should '#print_barcodes should send print request' do
        request = create :library_creation_request, target_asset: (create :library_tube, barcode: '111')
        @batch = create :batch
        @batch.requests << request
        printable = { request.id => 'on' }

        RestClient.expects(:post)

        post :print_barcodes, printer: barcode_printer.name, count: '3', printable: printable, batch_id: (@batch.id).to_s
      end

      should '#print_multiplex_barcodes should send print request' do
        pipeline = create :pipeline,
          name: 'Test pipeline',
          workflow: LabInterface::Workflow.create!(item_limit: 8),
          multiplexed: true
        batch = pipeline.batches.create!
        library_tube = create :library_tube, barcode: '111'
        printable = { library_tube.id => 'on' }

        RestClient.expects(:post)

        post :print_multiplex_barcodes, printer: barcode_printer.name, count: '3', printable: printable, batch_id: (batch.id).to_s
      end
    end
  end
end
