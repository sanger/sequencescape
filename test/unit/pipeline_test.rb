# frozen_string_literal: true

require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    should have_one :workflow
    should have_many :batches
    should have_many :controls
    should have_many :request_information_types # , :through => :pipeline_request_information_types
    should have_many :pipeline_request_information_types

    # should_require_attributes :name

    context 'sequencing_pipeline#read length consistency among batch requests' do
      setup do
        @sample = create(:sample)

        @request_type = create(:request_type, name: 'sequencing', target_asset_type: nil)
        @pipeline = create(:sequencing_pipeline, name: 'sequencing pipeline', request_types: [@request_type])
        @request1 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, :scanned_into_lab, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request2 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, :scanned_into_lab, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )
      end

      should 'return true if not any request was selected' do
        @batch = create(:batch)

        assert @pipeline.is_read_length_consistent_for_batch?(@batch)
      end

      should "return true if the requests don't make use of the read_length attribute" do
        @batch = @pipeline.batches.create!(requests: [@request1, @request2])

        assert @pipeline.is_read_length_consistent_for_batch?(@batch)
      end

      should 'check that all the requests has the read_length attribute defined' do
        @request2.request_metadata.read_length = nil
        @batch = @pipeline.batches.create(requests: [@request1, @request2])

        assert_not @pipeline.is_read_length_consistent_for_batch?(@batch)
      end

      should 'check that the read_length attribute is the same in all the requests' do
        @request1.request_metadata.read_length = 76
        @request2.request_metadata.read_length = 100
        @batch = @pipeline.batches.create(requests: [@request1, @request2])

        assert_not @pipeline.is_read_length_consistent_for_batch?(@batch)
      end

      should 'check that other pipelines are not affected by different read_length attributes' do
        @pipeline2 = create(:pipeline, name: 'other pipeline', request_types: [@request_type])
        @request1 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request2 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request1.request_metadata.read_length = 76
        @request2.request_metadata.read_length = 100
        @batch = @pipeline2.batches.create(requests: [@request1, @request2])

        assert @pipeline2.is_read_length_consistent_for_batch?(@batch)
      end
    end

    context 'sequencing_pipeline#requested_flowcell_type consistency among batch requests' do
      setup do
        @sample = create(:sample)

        @request_type = create(:request_type, name: 'sequencing', target_asset_type: nil)
        @pipeline = create(:sequencing_pipeline, name: 'sequencing pipeline', request_types: [@request_type])
        @request1 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, :scanned_into_lab, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request2 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, :scanned_into_lab, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )
      end

      should 'return true if no request was selected' do
        @batch = create(:batch)

        assert @pipeline.is_flowcell_type_consistent_for_batch?(@batch)
      end

      should "return true if the requests don't make use of the requested_flowcell_type attribute" do
        @batch = @pipeline.batches.create!(requests: [@request1, @request2])

        assert @pipeline.is_flowcell_type_consistent_for_batch?(@batch)
      end

      should 'check that the requested_flowcell_type attribute is the same in all the requests' do
        @request1.request_metadata.requested_flowcell_type = 'S2'
        @request2.request_metadata.requested_flowcell_type = 'S4'
        @batch = @pipeline.batches.create(requests: [@request1, @request2])

        assert_not @pipeline.is_flowcell_type_consistent_for_batch?(@batch)
      end

      should 'check that other pipelines are not affected by different requested_flowcell_type attributes' do
        @pipeline2 = create(:pipeline, name: 'other pipeline', request_types: [@request_type])
        @request1 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request2 =
          create(
            :sequencing_request,
            asset: create(:sample_tube, sample: @sample),
            target_asset: nil,
            request_type: @request_type
          )

        @request1.request_metadata.requested_flowcell_type = 'S2'
        @request2.request_metadata.requested_flowcell_type = 'S4'
        @batch = @pipeline2.batches.create(requests: [@request1, @request2])

        assert @pipeline2.is_flowcell_type_consistent_for_batch?(@batch)
      end
    end
  end
end
