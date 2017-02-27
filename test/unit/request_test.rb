# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  include AASM
  context 'A Request' do
    should belong_to :user
    should belong_to :request_type
    should belong_to :item
    should have_many :events
    should validate_presence_of :request_purpose
    should_have_instance_methods :pending?, :start, :started?, :fail, :failed?, :pass, :passed?, :reset, :workflow_id

    context 'while scoping with #for_order_including_submission_based_requests' do
      setup do
        @study = create :study
        @project = create :project

        @asset = create :empty_sample_tube
        @asset.aliquots.create!(sample: create(:sample, studies: [@study]))

        @asset2 = create :empty_sample_tube
        @asset2.aliquots.create!(sample: create(:sample, studies: [@study]))

        @order1 = create :order_with_submission, study: @study, assets: [@asset], project: @project
        @order2 = create :order,  study: @study, assets: [@asset], project: @project
        @order3 = create :order,  study: @study, assets: [@asset2], project: @project
        @order4 = create :order_with_submission,  study: @study, assets: [@asset2], project: @project

        @submission = @order1.submission
        @submission.orders.push(@order2)
        @submission.orders.push(@order3)

        @sequencing_request = create :request_with_sequencing_request_type, submission: @submission
        @request = create :request, order: @order1, asset: @asset, submission: @submission
        @request2 = create :request, order: @order2, submission: @submission

        @request3 = create :request, order: @order4, submission: @order4.submission
        @sequencing_request2 = create :request_with_sequencing_request_type, submission: @order4.submission
      end
      should 'the sequencing requests are included' do
        assert_equal 1, @order1.requests.length
        assert_equal 1, @order2.requests.length
        assert_equal 0, @order3.requests.length
        assert_equal 3, @submission.requests.length
        assert_equal 2, @submission.requests.for_order_including_submission_based_requests(@order1).length
        assert_equal 2, @submission.requests.for_order_including_submission_based_requests(@order2).length
      end
      should 'an order without requests should at least find the sequencing requests' do
        assert_equal 1, @submission.requests.for_order_including_submission_based_requests(@order3).length
      end

      should 'when filtering from submission and scoping with an order of another submission, none of the requests are included' do
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order1).length
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order2).length
        assert_equal 0, @order4.submission.requests.for_order_including_submission_based_requests(@order3).length
        assert_equal 0, @submission.requests.for_order_including_submission_based_requests(@order4).length
      end

      should 'requests from other submission behave independently' do
        assert_equal 1, @order4.requests.length
        assert_equal 2, @order4.submission.requests.length
        assert_equal 2, @order4.submission.requests.for_order_including_submission_based_requests(@order4).length
      end

      should 'can be used as any other request scope' do
        assert_equal 2, Request.for_order_including_submission_based_requests(@order1).length
        assert_equal 2, Request.for_order_including_submission_based_requests(@order2).length
        assert_equal 1, Request.for_order_including_submission_based_requests(@order3).length
        assert_equal 2, Request.for_order_including_submission_based_requests(@order4).length
      end
    end

    context '#next_request' do
      setup do
        @sample = create :sample

        @genotyping_request_type = create :request_type, name: 'genotyping'
        @cherrypick_request_type = create :request_type, name: 'cherrypick', target_asset_type: nil
        @submission = FactoryHelp::submission(request_types: [@cherrypick_request_type, @genotyping_request_type].map(&:id), asset_group_name: 'to avoid asset errors')
        @item = create :item, submission: @submission

        @genotype_pipeline = create :pipeline, name: 'genotyping pipeline', request_types: [@genotyping_request_type]
        @cherrypick_pipeline = create :pipeline, name: 'cherrypick pipeline', request_types: [@cherrypick_request_type], next_pipeline_id: @genotype_pipeline.id, asset_type: 'LibraryTube'

        @request1 = create(
          :request_without_assets,
          item: @item,
          asset: create(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(sample: @sample) },
          target_asset: nil,
          submission: @submission,
          request_type: @cherrypick_request_type,
          pipeline: @cherrypick_pipeline
        )
      end
      context 'with valid input' do
        setup do
          @request2 = create :request, item: @item, submission: @submission, request_type: @genotyping_request_type, pipeline: @genotype_pipeline
        end
        should 'return the correct next request' do
          assert_equal [@request2], @request1.next_requests(@cherrypick_pipeline)
        end
      end

      context 'where asset hasnt been created for second request' do
        setup do
          @request2 = create :request, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type, pipeline: @genotype_pipeline
        end
        should 'return the correct next request' do
          assert_equal [@request2], @request1.next_requests(@cherrypick_pipeline)
        end
      end

      context '#associate_pending_requests_for_downstream_pipeline' do
        setup do
          @request2 = create :request_without_assets, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type, pipeline: @genotype_pipeline
          @request3 = create :request_without_assets, asset: nil, item: @item, submission: @submission, request_type: @genotyping_request_type, pipeline: @genotype_pipeline

          @batch = @cherrypick_pipeline.batches.create!(requests: [@request1])

          @request1.reload
          @request2.reload
        end
        should 'set the target asset of request 1 to be the asset of request 2' do
          assert_equal @request1.target_asset, @request2.asset
        end
      end
    end

    context '#copy' do
       setup do
         @study = create :study
         @workflow = create :submission_workflow
         @request_type = create :request_type
         @item         = create :item
         @request = create :request, request_type: @request_type, study: @study, workflow: @workflow, item: @item, state: 'failed'
         @new_request = @request.copy
       end

       should 'return same properties' do
         @request.reload
         @new_request.reload
         original_attributes = @request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
         copied_attributes   = @new_request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
         assert_equal original_attributes, copied_attributes
       end

       should 'return same item_id' do
         assert_equal @request.item_id, @new_request.item_id
       end

       should 'remove target_asset' do
         assert_equal @new_request.target_asset_id, nil
       end

       should 'be pending' do
         assert @new_request.pending?
       end
    end

    context '#workflow' do
      setup do
        @study = create :study
        @workflow = create :submission_workflow
        @request_type = create :request_type
        @item         = create :item
        @request = create :request, request_type: @request_type, study: @study, workflow: @workflow, item: @item
      end

      should 'return a workflow id on request' do
        assert_kind_of Integer, @request.workflow_id
      end

      should 'return a valid value if workflow exists' do
        assert_equal @workflow.id, @request.workflow_id
      end
    end

    context '#after_create' do
      context 'successful' do
        setup do
          @workflow = create :submission_workflow
          @study = create :study
          # Create a new request
          assert_nothing_raised do
            @request = create :request, study: @study
          end
        end

        should 'not have ActiveRecord errors' do
          assert_equal 0, @request.errors.size
        end

        should 'have request as valid' do
          assert @request.valid?
        end
      end

      context 'failure' do
        setup do
          @workflow = create :submission_workflow
          @user = create :user
          @study = create :study
        end

        should 'not return an AR error' do
          assert_nothing_raised do
            @request = create :request, study: @study
          end
        end

        should 'fail to create a new request' do
          begin
            @requests = Request.all
            @request = create :request, study: @study
          rescue
            assert_equal @requests, Request.all
          end
        end
      end
    end

    context '#state' do
      setup do
        @study = create :study
        @item  = create :item
        @request = create :request_suitable_for_starting, study: @study, item: @item
        @user = create :admin
        @user.has_role 'owner', @study
      end

      context 'when a new request is created' do
        should "return the default state 'pending'" do
          assert_equal 'pending', @request.state
        end
      end

      context 'when started' do
        setup do
          @request.start!
        end

        should "return 'Started'" do
          assert_equal 'started', @request.state
        end

        should 'not be pending' do
          assert_equal false, @request.pending?
        end

        should 'not be passed' do
          assert_equal false, @request.passed?
        end

        should 'not be failed' do
          assert_equal false, @request.failed?
        end

        should 'be started' do
          assert @request.started?
        end

        context 'allow transition' do
          should 'to pass' do
            @request.state = 'started'
            @request.pass!
          end

          should 'to fail' do
            @request.state = 'started'
            @request.fail!
          end
        end
      end

      context 'when passed' do
        setup do
          @request.state = 'started'
          @request.pass!
        end

        should "return status of 'passed'" do
          assert_equal 'passed', @request.state
        end

        should 'not be pending' do
          assert_equal false, @request.pending?
        end

        should 'not be failed' do
          assert_equal false, @request.failed?
        end

        should 'not be started' do
          assert_equal false, @request.started?
        end

        should 'be passed' do
          assert @request.passed?
        end

        context 'do not allow the transition' do
          setup do
            @request.state = 'passed'
          end

          should 'to started' do
            # At least we'll know when and where it's blowing up.
            assert_raise(AASM::InvalidTransition) { @request.start! }
          end
        end
      end

      context 'when failed' do
        setup do
          @request.state = 'started'
          @request.fail!
        end

        should "return status of 'failed'" do
          assert_equal 'failed', @request.state
        end

        should 'not be pending' do
          assert_equal false, @request.pending?
        end

        should 'not be passed' do
          assert_equal false, @request.passed?
        end

        should 'not be started' do
          assert_equal false, @request.started?
        end

        should 'be failed' do
          assert @request.failed?
        end

        should 'not allow transition to passed' do
          assert_raise(AASM::InvalidTransition) do
            @request.pass!
          end
          assert_nothing_raised do
            @request.retrospective_pass!
          end
        end
      end
    end

    context '#open and #closed' do
      setup do
        @open_states = ['pending', 'started']
        @closed_states = ['passed', 'failed', 'cancelled']

        @all_states = @open_states + @closed_states

        @all_states.each do |state|
          create :request, state: state
        end

        assert_equal @all_states.size, Request.count
      end
      context 'open requests' do
        should 'total right number' do
          assert_equal @open_states.size, Request.opened.count
        end
      end
      context 'closed requests' do
        should 'total right number' do
          assert_equal @closed_states.size, Request.closed.count
        end
      end
    end

    context '#ready?' do
      setup do
        @library_creation_request = create(:library_creation_request_for_testing_sequencing_requests)
        @library_creation_request.asset.aliquots.each { |a| a.update_attributes!(project: create(:project)) }
        @library_tube = @library_creation_request.target_asset

        @library_creation_request_2 = create(:library_creation_request_for_testing_sequencing_requests, target_asset: @library_tube)
        @library_creation_request_2.asset.aliquots.each { |a| a.update_attributes!(project: create(:project)) }

        # The sequencing request will be created with a 76 read length (Standard sequencing), so the request
        # type needs to include this value in its read_length validation list (for example, single_ended_sequencing)
        @request_type = RequestType.find_by(key: 'single_ended_sequencing')

        @sequencing_request = create(:sequencing_request, asset: @library_tube, request_type: @request_type)
      end

      should 'check any non-sequencing request is always ready' do
        assert_equal true, @library_creation_request.ready?
      end

      should 'check a sequencing request is not ready if any of the library creation requests is not in a closed status type (passed, failed, cancelled)' do
        assert_equal false, @sequencing_request.ready?
      end

      should 'check a sequencing request is ready if at least one library creation request is in passed status while the others are closed' do
        @library_creation_request.start
        @library_creation_request.pass
        @library_creation_request.save!

        @library_creation_request_2.start
        @library_creation_request_2.cancel
        @library_creation_request_2.save!

        assert_equal true, @sequencing_request.ready?
      end

      should 'check a sequencing request is not ready if any of the library creation requests is not closed, although one of them is in passed status' do
        @library_creation_request.start
        @library_creation_request.pass
        @library_creation_request.save!

        assert_equal false, @sequencing_request.ready?
      end

      should 'check a sequencing request is not ready if none of the library creation requests are in passed status' do
        @library_creation_request.start
        @library_creation_request.fail
        @library_creation_request.save!

        @library_creation_request_2.start
        @library_creation_request_2.cancel
        @library_creation_request_2.save!

        assert_equal false, @sequencing_request.ready?
      end
    end

    context '#customer_responsible' do
      setup do
        @request = create :library_creation_request
        @request.state = 'started'
      end

      should 'update when request is started' do
        @request.request_metadata.update_attributes!(customer_accepts_responsibility: true)
        assert @request.request_metadata.customer_accepts_responsibility?
      end

      should 'not update once a request is failed' do
        @request.fail!
        assert_raise ActiveRecord::RecordInvalid do
          @request.request_metadata.update_attributes!(customer_accepts_responsibility: true)
        end
      end
    end
  end
end
