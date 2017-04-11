# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class LinearSubmissionTest < ActiveSupport::TestCase
  MX_ASSET_COUNT = 5
  SX_ASSET_COUNT = 4

  context 'LinearSubmission' do
    should belong_to :study
    should belong_to :user
  end

  context 'A LinearSubmission' do
    setup do
      @workflow = create :submission_workflow

      @study = build :study
      @project = build :project
      @user = build :user
    end

    context 'build (Submission factory)' do
      setup do
        @sequencing_request_type = create :sequencing_request_type
        @purpose = create :plate_purpose, name: 'mock purpose', type: 'Tube::StandardMx', target_type: 'MultiplexedLibraryTube'
        @request_options = { 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' }
      end

      context 'multiplexed submission' do
        context 'Customer decision propagation' do
          setup do
            @mpx_request_type = create :well_request_type, target_purpose: @purpose, for_multiplexing: true
            @mpx_request_type_ids = [@mpx_request_type.id, @sequencing_request_type.id]
            @our_product_criteria = create :product_criteria

            @basic_options = {
              study: @study,
              project: @project,
              workflow: @workflow,
              user: @user,
              request_types: @mpx_request_type_ids,
              request_options: @request_options,
              product: @our_product_criteria.product
            }

            @current_report = create :qc_report, product_criteria: @our_product_criteria
            @stock_well = create :well
            @request_well = create :well
            @request_well.stock_wells.attach!([@stock_well])
            @request_well.reload
            @expected_metric = create :qc_metric, asset: @stock_well, qc_report: @current_report, qc_decision: 'manually_failed', proceed: true

            @mpx_submission = LinearSubmission.build!(@basic_options.merge(assets: [@request_well]))
            @mpx_submission.save!
          end

          should 'set an appropriate criteria and set responsibility' do
            @mpx_submission.process!
            @mpx_submission.requests.each do |request|
              assert request.qc_metrics.include?(@expected_metric), "Metric not included in #{request.request_type.name}: #{request.qc_metrics.inspect}"
              assert_equal true, request.request_metadata.customer_accepts_responsibility, "Customer doesn't accept responsibility"
            end
          end
        end

        context 'basic behaviour' do
          setup do
            @mpx_assets = (1..MX_ASSET_COUNT).map { |i| create(:sample_tube, name: "MX-asset#{i}") }
            @mpx_asset_group = create :asset_group, name: 'MPX', assets: @mpx_assets

            @mpx_request_type = create :multiplexed_library_creation_request_type, target_purpose: @purpose
            @mpx_request_type_ids = [@mpx_request_type.id, @sequencing_request_type.id]

            @basic_options = {
              study: @study,
              project: @project,
              workflow: @workflow,
              user: @user,
              assets: @mpx_assets,
              request_types: @mpx_request_type_ids,
              request_options: @request_options
            }

            @mpx_submission = LinearSubmission.build!(@basic_options)
            @mpx_submission.save!
          end

          should 'be a multiplexed submission' do
            assert @mpx_submission.multiplexed?
          end

          should "not save a comment if one isn't supplied" do
            assert @mpx_submission.comments.blank?
          end

          context '#process!' do
            context 'single request' do
              setup do
                @comment_count = Comment.count
                @request_count = Request.count
                @item_count    = Item.count
                @mpx_submission.process!
              end

              # Ideally these would be separate asserts, but the setup phase is so slow
              # that we'll wrap them together. If the setup phase can be improved we
              # can split them out again
              should 'create requests and items but not comments' do
                assert_equal MX_ASSET_COUNT + 1, Request.count - @request_count
                assert_equal MX_ASSET_COUNT, Item.count - @item_count
                assert_equal @comment_count, Comment.count
              end
            end

            context 'multiple requests after plexing' do
              setup do
                @sequencing_request_type_2 = create :sequencing_request_type
                @mpx_request_type_ids = [@mpx_request_type.id, @sequencing_request_type_2.id, @sequencing_request_type.id]

                @multiple_mpx_submission = LinearSubmission.build!(
                  study: @study,
                  project: @project,
                  workflow: @workflow,
                  user: @user,
                  assets: @mpx_assets,
                  request_types: @mpx_request_type_ids,
                  request_options: @request_options
                )

                @comment_count = Comment.count
                @request_count = Request.count
                @item_count    = Item.count

                @multiple_mpx_submission.process!
              end

              # Ideally these would be separate shoulds, but the setup phase is so slow
              # that we'll wrap them together. If the setup phase can be improved we
              # can split them out again
              should 'create requests and items but not comments' do
                assert_equal MX_ASSET_COUNT + 2, Request.count - @request_count
                assert_equal MX_ASSET_COUNT, Item.count - @item_count
                assert_equal @comment_count, Comment.count
              end
            end
          end
        end
      end

      context 'single-plex submission' do
        setup do
          @assets = (1..SX_ASSET_COUNT).map { |i| create(:sample_tube, name: "Asset#{i}") }
          @asset_group = create :asset_group, name: 'non MPX', assets: @assets

          @request_type_1 = create :request_type, name: 'request type 1'
          @library_creation_request_type = create :library_creation_request_type
          @request_type_ids = [@request_type_1.id, @library_creation_request_type.id, @sequencing_request_type.id]

          @submission = LinearSubmission.build!(
            study: @study,
            project: @project,
            workflow: @workflow,
            user: @user,
            assets: @assets,
            request_types: @request_type_ids,
            request_options: @request_options,
            comments: 'This is a comment'
          )
          @submission.save!
        end

        should 'not be a multiplexed submission' do
          assert !@submission.multiplexed?
        end

        should 'save request_types as array of Fixnums' do
          assert_kind_of Array, @submission.orders.first.request_types
          assert @submission.orders.first.request_types.all? { |sample| sample.kind_of?(Integer) }
        end

        should "save a comment if there's one passed in" do
          assert_equal ['This is a comment'], @submission.comments
        end

        context '#process!' do
          setup do
            @request_count = Request.count
            @submission.process!
          end

         should "change Request.count by #{SX_ASSET_COUNT * 3}" do
           assert_equal SX_ASSET_COUNT * 3, Request.count - @request_count, "Expected Request.count to change by #{SX_ASSET_COUNT * 3}"
         end

          context '#create_requests_for_items' do
            setup do
              @request_count =  Request.count
              @comment_count =  Comment.count
              @submission.create_requests
            end

           should "change Request.count by #{SX_ASSET_COUNT * 3}" do
             assert_equal SX_ASSET_COUNT * 3,  Request.count  - @request_count, "Expected Request.count to change by #{SX_ASSET_COUNT * 3}"
           end

           should "change Comment.count by #{SX_ASSET_COUNT * 3}" do
             assert_equal SX_ASSET_COUNT * 3,  Comment.count  - @comment_count, "Expected Comment.count to change by #{SX_ASSET_COUNT * 3}"
           end

            should 'assign submission ids to the requests' do
              assert_equal @submission, @submission.items.first.requests.first.submission
            end

            context 'request type 1' do
              setup do
                @request_to_check = @submission.items.first.requests.find_by!(request_type_id: @request_type_1.id)
              end

              subject { @request_to_check.request_metadata }
              should_default_everything(Request::Metadata)
            end

            context 'library creation request type' do
              setup do
                @request_to_check = @submission.items.first.requests.find_by!(request_type_id: @library_creation_request_type.id)
              end

              subject { @request_to_check.request_metadata }
              should_default_everything_but(Request::Metadata, :fragment_size_required_to, :fragment_size_required_from)

              should 'assign fragment_size_required_to and assign fragment_size_required_from' do
                assert_equal '200', subject.fragment_size_required_to
                assert_equal '150', subject.fragment_size_required_from
              end
            end

            context 'sequencing request type' do
              setup do
                @request_to_check = @submission.items.first.requests.find_by!(request_type_id: @sequencing_request_type.id)
              end

              subject { @request_to_check.request_metadata }
              should_default_everything_but(Request::Metadata, :read_length)

              should 'assign read_length' do
                assert_equal 108, subject.read_length
              end
            end
          end
        end
      end
    end

    context 'process with a multiplier for request type' do
      setup do
        @study = create :study
        @project = create :project
        @workflow = create :submission_workflow

        @user = create :user

        @project = create :project
        @project.enforce_quotas = true

        @asset_1 = create(:sample_tube)
        @asset_2 = create(:sample_tube)

        @mx_request_type = create :multiplexed_library_creation_request_type, asset_type: 'SampleTube', target_asset_type: 'LibraryTube', initial_state: 'pending', name: 'Multiplexed Library Creation', order: 1, key: 'multiplexed_library_creation'
        @lib_request_type = create :library_creation_request_type, asset_type: 'SampleTube', target_asset_type: 'LibraryTube', initial_state: 'pending', name: 'Library Creation', order: 1, key: 'library_creation'
        @pe_request_type = create :request_type, asset_type: 'LibraryTube', initial_state: 'pending', name: 'PE sequencing', order: 2, key: 'pe_sequencing'
        @se_request_type = create :request_type, asset_type: 'LibraryTube', initial_state: 'pending', name: 'SE sequencing', order: 2, key: 'se_sequencing'

        @submission_with_multiplication_factor = LinearSubmission.build!(
          study: @study,
          project: @project,
          workflow: @workflow,
          user: @user,
          assets: [@asset_1, @asset_2],
          request_types: [@lib_request_type.id, @pe_request_type.id],
          request_options: { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @lib_request_type.id.to_s.to_sym => '1' }, 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' },
          comments: ''
        )
        @mx_submission_with_multiplication_factor = LinearSubmission.build!(
          study: @study,
          project: @project,
          workflow: @workflow,
          user: @user,
          assets: [@asset_1, @asset_2],
          request_types: [@mx_request_type.id, @pe_request_type.id],
          request_options: { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @mx_request_type.id.to_s.to_sym => '1' }, 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' },
          comments: ''
        )
      end

      context 'when a multiplication factor of 5 is provided' do
        context 'for non multiplexed libraries and sequencing' do
          setup do
            @request_count = Request.count
            @submission_with_multiplication_factor.process!
          end

           should 'change Request.count by 12' do
             assert_equal 12, Request.count - @request_count, 'Expected Request.count to change by 12'
           end

          should 'create 2 library requests' do
            lib_requests = Request.where(submission_id: @submission_with_multiplication_factor, request_type_id: @lib_request_type.id)
            assert_equal 2, lib_requests.size
          end

          should 'create 10 sequencing requests' do
            seq_requests = Request.where(submission_id: @submission_with_multiplication_factor, request_type_id: @pe_request_type.id)
            assert_equal 10, seq_requests.size
          end
        end

        context 'for non multiplexed libraries and sequencing' do
          setup do
            @mx_submission_with_multiplication_factor.process!
          end
        end
      end
    end
  end
end
