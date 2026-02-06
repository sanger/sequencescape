# frozen_string_literal: true

require 'test_helper'

class BatchesControllerTest < ActionController::TestCase
  context 'BatchesController' do
    setup do
      @controller = BatchesController.new
      @request = ActionController::TestRequest.create(@controller)
    end
    should_require_login

    context 'with a false user for npg' do
      setup { session[:current_user] = :false }

      context 'NPG xml view' do
        setup do
          pipeline = create(:sequencing_pipeline)

          @study = create(:study)
          @project = create(:project)
          @sample = create(:sample)
          @submission = create(:submission_without_order, priority: 3)

          @library =
            create(:empty_library_tube).tap do |library_tube|
              library_tube.aliquots.create!(
                sample: @sample,
                project: @project,
                study: @study,
                library: library_tube,
                library_type: 'Standard'
              )
            end

          @phix = create(:spiked_buffer, :tube_barcode)

          @lane = create(:empty_lane, qc_state: 'failed')
          @lane.labware.parents << @library

          @request_one =
            pipeline.request_types.first.create!(
              asset: @library,
              target_asset: @lane,
              project: @project,
              study: @study,
              submission: @submission,
              request_metadata_attributes: {
                fragment_size_required_from: 100,
                fragment_size_required_to: 200,
                read_length: 76
              }
            )

          @batch = create(:batch, pipeline:)
          @batch.batch_requests.create!(request: @request_one, position: 1)
          @batch.reload
          @batch.start!(create(:user))
        end

        context 'when there is no PhiX' do
          setup { get :show, params: { id: @batch.id, format: :xml } }

          should 'Respond with xml' do
            assert_equal 'application/xml', @response.media_type
          end

          should 'have api version attribute on root object' do
            assert_response :success
            assert_select "lane[position='1'][id='#{@lane.id}'][priority='3']"
            assert_select "library[request_id='#{@request_one.id}'][qc_state='fail']"
          end

          should 'expose the library information correctly' do
            # rubocop:todo Layout/LineLength
            assert_select "sample[library_id='#{@library.receptacle.id}'][library_name='#{@library.name}'][library_type='Standard']"
            # rubocop:enable Layout/LineLength
          end

          should 'not have information about spiked in buffers' do
            assert_select 'hyb_buffer', 0
          end
        end

        context 'when PhiX is spiked in at sequencing stage' do
          setup do
            @lane.labware.parents << @phix

            get :show, params: { id: @batch.id, format: :xml }
          end

          should 'have information about spiked in buffers' do
            assert_select 'hyb_buffer', 1
            assert_select "sample[library_id='#{@phix.aliquots.first.library_id}']", 1
            assert_select "tag[tag_id='#{@phix.aliquots.first.tag_id}']", 1
            assert_select 'index', @phix.aliquots.first.tag.map_id.to_s, 1
            assert_select 'expected_sequence', @phix.aliquots.first.tag.oligo.to_s, 1
            assert_select 'tag_group_id', @phix.aliquots.first.tag.tag_group_id.to_s, 1
          end
        end

        context 'when PhiX is spiked in during library prep' do
          context 'when the lane has a single SpikedBuffer ancestor' do
            setup do
              @library.parents << @phix

              get :show, params: { id: @batch.id, format: :xml }
            end

            should 'have information about spiked in buffers' do
              assert_select 'hyb_buffer', 1
              assert_select "sample[library_id='#{@phix.aliquots.first.library_id}']", 1
              assert_select "tag[tag_id='#{@phix.aliquots.first.tag_id}']", 1
              assert_select 'index', @phix.aliquots.first.tag.map_id.to_s, 1
              assert_select 'expected_sequence', @phix.aliquots.first.tag.oligo.to_s, 1
              assert_select 'tag_group_id', @phix.aliquots.first.tag.tag_group_id.to_s, 1
            end
          end

          context 'when the lane has multiple SpikedBuffer ancestors' do
            setup do
              @phix_with_parent = create(:spiked_buffer_with_parent, :tube_barcode)
              @library.parents << @phix_with_parent

              get :show, params: { id: @batch.id, format: :xml }
            end

            should 'have information about spiked in buffers' do
              assert_select 'hyb_buffer', 1
              assert_select "sample[library_id='#{@phix_with_parent.aliquots.first.library_id}']", 1
              assert_select "tag[tag_id='#{@phix_with_parent.aliquots.first.tag_id}']", 1
              assert_select 'index', @phix_with_parent.aliquots.first.tag.map_id.to_s, 1
              assert_select 'expected_sequence', @phix_with_parent.aliquots.first.tag.oligo.to_s, 1
              assert_select 'tag_group_id', @phix_with_parent.aliquots.first.tag.tag_group_id.to_s, 1
            end
          end
        end
      end
    end

    context 'with a user logged in' do
      setup do
        @user = create(:user)
        session[:user] = @user.id
      end

      context 'with a few batches' do
        setup do
          @batch_one = create(:batch)
          @batch_two = create(:batch)
        end

        should '#index' do
          get :index

          assert_response :success
          assert assigns(:batches)
        end

        should '#show' do
          get :show, params: { id: @batch_one.id }

          assert_response :success
          assert_equal @batch_one, assigns(:batch)
        end

        should '#edit' do
          get :edit, params: { id: @batch_one }

          assert_response :success
          assert_equal @batch_one, assigns(:batch)
        end
      end

      context '#verify_layout' do
        setup do
          @pipeline = create(:pipeline)
          @labware1 = create(:sample_tube, barcode: '123456')
          @labware2 = create(:sample_tube, barcode: '654321')

          @request1 = @pipeline.request_types.last.create!(asset: @labware1)
          @request2 = @pipeline.request_types.last.create!(asset: @labware2)

          @batch = @pipeline.batches.create!
          @batch.batch_requests.create!(request: @request1, position: 2)
          @batch.batch_requests.create!(request: @request2, position: 1)
        end

        should 'accepts valid layouts' do
          post :verify_layout,
               params: {
                 :id => @batch.id,
                 'barcode_0' => '3980654321768',
                 'barcode_1' => '3980123456878',
                 :verification_flavour => 'tube'
               }

          assert_equal 'All of the tubes are in their correct positions.', flash[:notice]
        end

        should 'rejects invalid layouts' do
          post :verify_layout,
               params: {
                 :id => @batch.id,
                 'barcode_0' => '3980123456878',
                 'barcode_1' => '3980654321768',
                 :verification_flavour => 'tube'
               }

          assert_equal [
            'The tube at position 1 is incorrect: expected NT654321L.',
            'The tube at position 2 is incorrect: expected NT123456W.'
          ],
                       flash[:error]
        end

        should 'rejects missing tubes' do
          post :verify_layout,
               params: { :id => @batch.id, 'barcode_0' => '3980654321768', 'barcode_1' => '',
                         :verification_flavour => 'tube' }

          assert_equal ['The tube at position 2 is incorrect: expected NT123456W.'], flash[:error]
        end

        # the actual verification logic is tested in the batch model tests
        should 'call correct batch method for amp plate verification' do
          Batch.stubs(:find).with(@batch.id.to_s).returns(@batch)
          @batch.expects(:verify_amp_plate_layout).returns(true)
          post :verify_layout,
               params: {
                 :id => @batch.id,
                 'barcode_0' => 'dummybarcode',
                 'barcode_1' => 'dummybarcode2',
                 :verification_flavour => 'amp_plate'
               }
        end
      end

      context 'with a cherrypick pipeline' do
        setup do
          @pipeline = create(:cherrypick_pipeline)
          @requests = create_list(:cherrypick_request_for_pipeline, 2, request_type: @pipeline.request_types.first)
          @selected_request = @requests.first
          @submission = @selected_request.submission || raise('No Sub')
          @plate = @selected_request.asset.plate || raise('No plate')
        end

        should '#create' do
          post :create,
               params: {
                 id: @pipeline.id,
                 utf8: '✓',
                 action_on_requests: 'create_batch',
                 request_group: {
                   "#{@plate.id}, #{@submission.id}" => '1'
                 },
                 "request_group_#{@plate.id}_#{@submission.id}_size": '1',
                 commit: 'Submit'
               }
        end
      end

      context 'actions' do
        setup do
          @pipeline_next = create(:pipeline, name: 'Next pipeline')
          @pipeline = create(:pipeline, name: 'New Pipeline')
          @pipeline_qc_manual = create(:pipeline, name: 'Manual quality control')
          @pipeline_qc = create(:pipeline, name: 'quality control')

          @ws = @pipeline.workflow # :name => 'A New workflow', :item_limit => 2
          @ws_two = @pipeline_qc.workflow # :name => 'Another workflow', :item_limit => 2
          @ws_two.update!(locale: 'External')

          @batch_one = create(:batch, pipeline: @pipeline)
          @batch_two = create(:batch, pipeline: @pipeline_qc)

          @sample = create(:sample_tube)
          @library1 = create(:empty_library_tube)
          @library1.parents << @sample
          @library2 = create(:empty_library_tube)
          @library2.parents << @sample

          @target_one = create(:sample_tube)
          @target_two = create(:sample_tube)

          # TODO: add a control_request_type to pipeline...
          @request_one =
            @pipeline.request_types.first.create!(
              asset: @library1,
              target_asset: @target_one,
              project: create(:project)
            )
          @batch_one.batch_requests.create!(request: @request_one, position: 1)
          @request_two =
            @pipeline.request_types.first.create!(
              asset: @library2,
              target_asset: @target_two,
              project: create(:project)
            )
          @batch_one.batch_requests.create!(request: @request_two, position: 2)
          @batch_one.reload
        end

        should '#update' do
          @pipeline_user = create(:pipeline_admin, login: 'ur1', first_name: 'Ursula', last_name: 'Robinson')
          put :update, params: { id: @batch_one.id, batch: { assignee_id: @pipeline_user.id } }

          assert_redirected_to batch_path(assigns(:batch))
          assert_equal assigns(:batch).assignee, @pipeline_user
          assert_includes flash[:notice], 'Assigned to Ursula Robinson (ur1)'
        end

        should 'redirect on update without param' do
          put :update, params: { id: @batch_one.id, batch: { id: 'bad id' } }

          assert_response :redirect
        end

        context '#create' do
          setup do
            @old_count = Batch.count

            @request_three =
              @pipeline.request_types.first.create!(asset: @library1, project: FactoryBot.create(:project))
            @request_four =
              @pipeline.request_types.first.create!(asset: @library2, project: FactoryBot.create(:project))
          end

          context 'redirect to #show new batch' do
            setup do
              post :create, params: { id: @pipeline.id, request: { @request_three.id => '0', @request_four.id => '1' } }
            end

            should 'create_batch  with no controls' do
              assert_equal @old_count + 1, Batch.count
              assert_redirected_to batch_path(assigns(:batch))
            end
          end

          context 'hide_requests' do
            setup do
              post :create,
                   params: {
                     id: @pipeline.id,
                     request: {
                       @request_three.id => '0',
                       @request_four.id => '1'
                     },
                     action_on_requests: 'hide_from_inbox'
                   }
            end

            should 'hide the requests from the inbox' do
              assert_redirected_to pipeline_path(@pipeline)
              assert_equal 'Requests hidden from inbox', flash[:notice]
              assert_not @request_three.reload.hold?
              assert_predicate @request_four.reload, :hold?
            end
          end

          context 'cancel_requests' do
            setup do
              post :create,
                   params: {
                     id: @pipeline.id,
                     request: {
                       @request_three.id => '0',
                       @request_four.id => '1'
                     },
                     action_on_requests: 'cancel_requests'
                   }
            end

            should 'cancel the requests' do
              assert_redirected_to pipeline_path(@pipeline)
              assert_equal 'Requests cancelled', flash[:notice]
              assert_not @request_three.reload.cancelled?
              assert_predicate @request_four.reload, :cancelled?
            end
          end

          context 'create batch and assign requests' do
            setup do
              @old_count = Batch.count
              post :create, params: { id: @pipeline.id, request: { @request_three.id => '1', @request_four.id => '1' } }
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
            get :released, params: { id: @pipeline.id }

            assert_response :success
          end
        end

        context '#fail' do
          should 'render fail reasons when internal' do
            get :fail, params: { id: @batch_one.id }

            assert_predicate @batch_one.workflow, :source_is_internal?
            assert_response :success
            assert assigns(:fail_reasons)
          end

          should 'render fail reasons when external' do
            get :fail, params: { id: @batch_two.id }

            assert_not @batch_two.workflow.source_is_internal?
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
            setup { post :fail_items, params: { id: @batch_one.id, failure: { reason: '', comment: '' } } }
            should 'not allow failing a batch/items without specifying a reason and set the flash' do
              assert_includes flash[:error], 'Please specify a failure reason for this batch'
              assert_redirected_to action: :fail, id: @batch_one.id
            end
          end

          context 'posting with a failure reason' do
            context 'individual items' do
              setup do
                EventSender.expects(:send_fail_event).returns(true).times(1)
                post :fail_items,
                     params: {
                       id: @batch_one.id,
                       failure: {
                         reason: 'PCR not completed',
                         comment: ''
                       },
                       requested_fail: {
                         @request_one.id.to_s => 'on'
                       }
                     }
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

            # Handful of edge cases that were tested in batch.rb, but the behaviour has moved. Covers:
            # - Non 'on' values returned from the front-end (Which indicates something strange has happened with the
            #   checkboxes)
            # - Filtering of 'control' ids. (Associated with some old batches)
            context 'odd values' do
              setup do
                EventSender.expects(:send_fail_event).times(0)
                post :fail_items,
                     params: {
                       id: @batch_one.id,
                       failure: {
                         reason: 'PCR not completed',
                         comment: ''
                       },
                       requested_fail: {
                         @request_one.id.to_s => 'blue',
                         'control' => 'on'
                       }
                     }
              end
              should 'not create a failure' do
                assert_equal 0, @batch_one.failures.size
                assert_equal 2, @batch_one.size

                # First item
                assert_equal 0, @batch_one.requests.first.failures.size

                # Second item
                assert_equal 0, @batch_one.requests.last.failures.size
              end
            end

            # If request ids are missing we were previously throwing a 404, and failing half the batch
            # Now we should abort the whole action with an error
            context 'odd values' do
              setup do
                EventSender.expects(:send_fail_event).times(0)
                post :fail_items,
                     params: {
                       id: @batch_one.id,
                       failure: {
                         reason: 'PCR not completed',
                         comment: ''
                       },
                       requested_fail: {
                         @request_one.id.to_s => 'on',
                         'not_a_request' => 'on'
                       }
                     }
              end
              should 'not create a failure' do
                assert_equal 0, @batch_one.failures.size
                assert_equal 2, @batch_one.size

                # First item
                assert_equal 0, @batch_one.requests.first.failures.size

                # Second item
                assert_equal 0, @batch_one.requests.last.failures.size
                assert_includes flash['error'], "Couldn't find all Requests with 'id'"
              end
            end
          end
        end
      end
    end

    context 'Find by barcode (found)' do
      setup do
        @controller.stubs(:current_user).returns(@admin)
        @batch = FactoryBot.create(:batch)
        request = FactoryBot.create(:request)
        @batch.requests << request
        r = @batch.requests.first
        @e = r.lab_events.create(description: 'Cluster generation')
        @e.add_descriptor Descriptor.new(name: 'Chip Barcode', value: 'Chip Barcode: 62c7gaaxx')
        @e.batch_id = @batch.id
        @e.save
        get :find_batch_by_barcode, params: { id: '62c7gaaxx' }, format: :xml
      end
      should 'show batch' do
        assert_response :success
        assert_equal 'application/xml', @response.media_type
        assert_template 'batches/show'
      end
    end

    context 'Find by barcode (not found)' do
      setup do
        @controller.stubs(:current_user).returns(@admin)
        get :find_batch_by_barcode, params: { id: '62c7axx' }, format: :xml
      end
      should 'show error' do
        # this is the wrong response!
        assert_response :success
        assert_equal 'application/xml', @response.media_type
        assert_template 'batches/batch_error'
      end
    end

    context 'Send print requests' do
      attr_reader :barcode_printer

      setup do
        @user = create(:user)
        @controller.stubs(:current_user).returns(@user)
        @barcode_printer = create(:barcode_printer)
      end

      should '#print_plate_barcodes should send print request' do
        study = create(:study)
        project = create(:project)
        asset = create(:empty_sample_tube)
        order_role = OrderRole.new role: 'test'

        order = create(:order, order_role: order_role, study: study, assets: [asset], project: project)
        request =
          create(
            :well_request,
            asset: create(:well_with_sample_and_plate),
            target_asset: create(:well_with_sample_and_plate),
            order: order
          )
        @batch = create(:batch)
        @batch.requests << request

        RestClient.expects(:post)

        post :print_plate_barcodes,
             params: {
               printer: barcode_printer.name,
               count: '3',
               printable: {
                 @batch.output_plates.first.human_barcode => 'on'
               },
               batch_id: @batch.id.to_s
             }
      end

      should '#print_barcodes should send print request' do
        request = create(:library_creation_request, target_asset: create(:library_tube, barcode: '111'))
        @batch = create(:batch)
        @batch.requests << request
        printable = { request.id => 'on' }

        RestClient.expects(:post)

        post :print_barcodes,
             params: {
               printer: barcode_printer.name,
               count: '3',
               printable: printable,
               batch_id: @batch.id.to_s
             }
      end

      should '#print_amp_plate_barcodes should send print request' do
        sequencing_request = create(:sequencing_request_with_assets)
        tube = sequencing_request.asset
        @batch = create(:batch)
        @batch.requests << sequencing_request
        printable = { tube.human_barcode => 'on' }

        RestClient.expects(:post)

        post :print_amp_plate_barcodes,
             params: {
               printer: barcode_printer.name,
               count: '3',
               printable: printable,
               batch_id: @batch.id.to_s
             }
      end
    end
  end
end
