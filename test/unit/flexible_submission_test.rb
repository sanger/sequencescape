# frozen_string_literal: true

require 'test_helper'

class FlexibleSubmissionTest < ActiveSupport::TestCase
  context 'FlexibleSubmission' do
    setup do
      @assets = create(:two_column_plate).wells.to_a
      @pooling = create(:pooling_method)
    end

    should belong_to :study
    should belong_to(:user).required

    context 'build (Submission factory)' do
      setup do
        @study = create(:study)
        @project = create(:project)
        @user = create(:user)

        @library_creation_request_type =
          create(:well_request_type, target_purpose: nil, for_multiplexing: true, pooling_method: @pooling)
        @sequencing_request_type = create(:sequencing_request_type)

        @request_type_ids = [@library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {
          'read_length' => '108',
          'fragment_size_required_from' => '150',
          'fragment_size_required_to' => '200'
        }
      end

      context 'multiplexed submission' do
        setup do
          @mpx_submission =
            create(
              :flexible_submission,
              study: @study,
              project: @project,
              user: @user,
              assets: @assets,
              request_types: @request_type_ids,
              request_options: @request_options
            ).submission
          @mpx_submission.built!
        end

        should 'be a multiplexed submission' do
          assert_predicate @mpx_submission, :multiplexed?
        end

        context '#process!' do
          context 'multiple requests' do
            setup do
              @request_count = Request.count
              @mpx_submission.process!
            end

            should "change Request.count by #{16 + 8}" do
              assert_equal (16 + 8), Request.count - @request_count
            end
          end
        end
      end

      context 'with qc_criteria' do
        setup do
          @our_product_criteria = create(:product_criteria)
          @current_report = create(:qc_report, product_criteria: @our_product_criteria)
          @stock_well = create(:well)

          @metric =
            create(:qc_metric, asset: @stock_well, qc_report: @current_report, qc_decision: 'failed', proceed: true)

          @assets.each do |qced_well|
            qced_well.stock_wells.attach!([@stock_well])
            qced_well.reload
          end

          @mpx_submission =
            create(
              :flexible_submission,
              study: @study,
              project: @project,
              user: @user,
              assets: @assets,
              request_types: @request_type_ids,
              request_options: @request_options,
              product: @our_product_criteria.product
            ).submission
          @mpx_submission.built!
        end

        should 'set an appropriate criteria and set responsibility' do
          @mpx_submission.process!
          @mpx_submission.requests.each do |request|
            assert_includes request.qc_metrics, @metric,
                            # rubocop:todo Layout/LineLength
                            "Metric not included in #{request.request_type.name}: List #{request.qc_metrics.inspect}, Expected: #{@metric}"

            # rubocop:enable Layout/LineLength
            assert_equal true,
                         request.request_metadata.customer_accepts_responsibility,
                         "Customer doesn't accept responsibility"
          end
        end
      end

      context 'cross study/project submissions' do
        setup do
          @study_b = create(:study)
          @project_b = create(:project)
          @request_count = Request.count
        end

        context 'specified at submission' do
          setup do
            @xs_mpx_submission =
              create(
                :flexible_submission,
                study: @study,
                project: @project,
                user: @user,
                assets: @assets.slice(0, 8),
                request_types: @request_type_ids,
                request_options: @request_options
              ).submission
            @xs_mpx_submission.built!
            @order_b =
              create(
                :flexible_submission,
                study: @study_b,
                project: @project_b,
                user: @user,
                assets: @assets.slice(8, 8),
                request_types: @request_type_ids,
                request_options: @request_options,
                submission: @xs_mpx_submission
              )
            @xs_mpx_submission.orders << @order_b
            @xs_mpx_submission.save!
          end

          should 'be a multiplexed submission' do
            assert_predicate @xs_mpx_submission, :multiplexed?
          end

          context '#process!' do
            context 'multiple requests' do
              setup { @xs_mpx_submission.reload.process! }

              should("change Request.count by #{16 + 8}") { assert_equal (16 + 8), Request.count - @request_count }

              should 'not set study or project post multiplexing' do
                assert_nil @sequencing_request_type.requests.last.initial_study_id
                assert_nil @sequencing_request_type.requests.last.initial_project_id
              end
            end
          end
        end

        context 'not specified at submission' do
          should 'not be valid for unpooled assets' do
            assert_raise(ActiveRecord::RecordInvalid) do
              create(
                :flexible_submission,
                study: nil,
                project: nil,
                user: @user,
                assets: @assets,
                request_types: @request_type_ids,
                request_options: @request_options
              ).submission
            end
          end

          context 'On pooled assets' do
            setup do
              @request_count = Request.count
              @pooled = create(:cross_pooled_well)
              @sub =
                create(
                  :flexible_submission,
                  study: nil,
                  project: nil,
                  user: @user,
                  assets: [@pooled],
                  request_types: @request_type_ids,
                  request_options: @request_options
                ).submission
              @sub.built!
              @sub.process!
            end

            should("change Request.count by #{1 + 8}") { assert_equal (1 + 8), Request.count - @request_count }

            should('not set request study or projects') do
              assert(@sub.requests.all? { |r| r.initial_study_id.nil? && r.initial_project_id.nil? })
            end
          end
        end
      end
    end

    context 'with target asset creation' do
      setup do
        @study = create(:study)
        @project = create(:project)
        @user = create(:user)
        mx_purpose = create(:mx_tube_purpose)
        @library_creation_request_type =
          create(:well_request_type, for_multiplexing: true, target_purpose: mx_purpose, pooling_method: @pooling)
        @sequencing_request_type = create(:sequencing_request_type)

        @request_type_ids = [@library_creation_request_type.id, @sequencing_request_type.id]

        @request_options = {
          'read_length' => '108',
          'fragment_size_required_from' => '150',
          'fragment_size_required_to' => '200'
        }
      end

      context 'multiplexed submission' do
        setup do
          @mpx_submission =
            create(
              :flexible_submission,
              study: @study,
              project: @project,
              user: @user,
              assets: @assets,
              request_types: @request_type_ids,
              request_options: @request_options
            ).submission
          @mpx_submission.built!
        end

        should 'be a multiplexed submission' do
          assert_predicate @mpx_submission, :multiplexed?
        end

        context '#process!' do
          context 'multiple requests' do
            setup do
              @request_count = Request.count
              @mpx_submission.process!
            end

            should "change Request.count by #{16 + 8}" do
              assert_equal (16 + 8), Request.count - @request_count
            end

            should 'set target assets according to the request_type.pool_by' do
              rows = (0...8).to_a
              used_assets = []

              @assets
                .group_by { |well| well.map.row }
                .each do |row, wells|
                  assert_predicate rows.delete(row), :present?, "Row #{row} was unexpected"
                  unique_target_assets = wells.map { |w| w.requests.first.target_asset }.uniq

                  assert_equal 1, unique_target_assets.count
                  assert_empty (used_assets & unique_target_assets), 'Target assets are reused'
                  used_assets.concat(unique_target_assets)
                end

              assert_empty rows, "Didn't see rows #{rows.to_sentence}"
            end
          end
        end
      end
    end

    context 'process with a multiplier for request type' do
      setup do
        @study = create(:study)
        @project = create(:project)
        @user = create(:user)

        @ux_request_type = create(:well_request_type, target_purpose: nil, for_multiplexing: false)
        @mx_request_type =
          create(:well_request_type, target_purpose: nil, for_multiplexing: true, pooling_method: @pooling)
        @pe_request_type =
          create(
            :request_type,
            asset_type: 'LibraryTube',
            initial_state: 'pending',
            name: 'PE sequencing',
            order: 2,
            key: 'pe_sequencing'
          )

        @request_type_ids = [@mx_request_type.id, @pe_request_type.id]

        @mx_submission_with_multiplication_factor =
          create(
            :flexible_submission,
            study: @study,
            project: @project,
            user: @user,
            assets: @assets,
            request_types: @request_type_ids,
            request_options: {
              :multiplier => {
                @pe_request_type.id.to_s.to_sym => '2',
                @mx_request_type.id.to_s.to_sym => '1'
              },
              'read_length' => '108',
              'fragment_size_required_from' => '150',
              'fragment_size_required_to' => '200'
            },
            comments: ''
          ).submission
        @mx_submission_with_multiplication_factor.built!
      end

      context 'when a multiplication factor of 2 is provided' do
        context 'for multiplexed libraries and sequencing' do
          setup { @mx_submission_with_multiplication_factor.process! }

          should 'create 16 library requests and 40 sequencing requests' do
            lib_requests =
              Request.where(
                submission_id: @mx_submission_with_multiplication_factor,
                request_type_id: @mx_request_type.id
              )

            assert_equal 16, lib_requests.count
            seq_requests =
              Request.where(
                submission_id: @mx_submission_with_multiplication_factor,
                request_type_id: @pe_request_type.id
              )

            assert_equal 16, seq_requests.count
          end
        end
      end
    end

    context 'correctly calculate multipliers' do
      setup do
        @study = create(:study)
        @project = create(:project)
        @user = create(:user)

        @ux_request_type = create(:well_request_type, target_purpose: nil, for_multiplexing: false)
        @mx_request_type =
          create(:well_request_type, target_purpose: nil, for_multiplexing: true, pooling_method: @pooling)
        @pe_request_type =
          create(
            :request_type,
            asset_type: 'LibraryTube',
            initial_state: 'pending',
            name: 'PE sequencing',
            order: 2,
            key: 'pe_sequencing'
          )

        @mx_request_type_ids = [@mx_request_type.id, @pe_request_type.id]
        @ux_request_type_ids = [@ux_request_type.id, @pe_request_type.id]
      end

      context 'with multiplexed requests' do
        context 'for multiplexed libraries and sequencing' do
          setup do
            @mx_submission_with_multiplication_factor =
              create(
                :flexible_submission,
                study: @study,
                project: @project,
                user: @user,
                assets: @assets,
                request_types: @mx_request_type_ids,
                comments: ''
              ).submission
          end

          should 'multiply the sequencing' do
            ids = []
            @mx_submission_with_multiplication_factor.orders.first.request_type_multiplier { |id| ids << id }

            assert_equal [:"#{@pe_request_type.id}"], ids
          end
        end
      end

      context 'with unplexed requests' do
        context 'for unplexed libraries and sequencing' do
          setup do
            @ux_submission_with_multiplication_factor =
              create(
                :flexible_submission,
                study: @study,
                project: @project,
                user: @user,
                assets: @assets,
                request_types: @ux_request_type_ids,
                comments: ''
              ).submission
          end

          should 'multiply the library creation' do
            ids = []
            @ux_submission_with_multiplication_factor.orders.first.request_type_multiplier { |id| ids << id }

            assert_equal [:"#{@ux_request_type.id}"], ids
          end
        end
      end
    end
  end
end
