# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

class DummyWorkflowController < WorkflowsController
  attr_accessor :flash, :batch

  def initialize
    @flash = {}
  end
end

class MultiplexedCherrypickingTaskTest < ActiveSupport::TestCase
  MockBc = Struct.new(:barcode)

  def self.shared
    context 'with tag clashes' do
      setup do
        tag_hash = Hash.new { |h, i| h[i] = create :tag }
        @tags = [1, 2, 3, 4, 5, 5, 6, 6].map { |i| tag_hash[i] }
        @requests = (1..8).map do |i|
          r = create :pooled_cherrypick_request
          r.asset.aliquots.first.update_attributes!(tag: @tags[i - 1])
          r
        end

        @batch = mock('batch')
        @batch.stubs(:requests).returns(@requests)
        @workflows_controller.batch = @batch
      end

      should 'return false' do
        assert !@task.do_task(@workflows_controller, params)
      end

      should 'set a flash[:notice] for failure' do
        @task.do_task(@workflows_controller, params)
        assert_not_nil @workflows_controller.flash[:error]
        assert_equal 'Duplicate tags in G1', @workflows_controller.flash[:error]
      end
    end
  end

  # Generate the request mapping according to the well array
  def request_location_hash
    Hash[@requests.each_with_index.map do |request, index|
      [request.id.to_s, @well_array[index]]
    end]
  end

  # Generate the parameters
  def params
    {
      request_locations: request_location_hash,
      commit: 'Next step',
      batch_id: '2',
      next_stage: 'true',
      workflow_id: '24',
      id: '2',
      plate_purpose_id: @purpose_id,
      existing_plate_barcode: @barcode,
      micro_litre_volume_required: '5'
    }
  end

  context 'AssignTubesToMultiplexedWellsHandler' do
    setup do
      @workflows_controller = DummyWorkflowController.new
      @task                 = create :multiplexed_cherrypicking_task
    end

    context '#do_assign_requests_to_multiplexed_wells_task with existing plate' do
      setup do
          @plate = create :plate

          @well_array = %w(A1 B1 C1 D1 E1 F1 G1 G1)

          @barcode = @plate.ean13_barcode
          @purpose_id = '33'
      end

      shared

      context 'with no tag clashes' do
        setup do
          tag_hash = Hash.new { |h, i| h[i] = create :tag }
          @tags = [1, 2, 3, 4, 5, 6, 7, 8].map { |i| tag_hash[i] }

          @requests = (1..8).map do |i|
            r = create :pooled_cherrypick_request
            r.asset.aliquots.first.update_attributes!(tag: @tags[i - 1])
            r
          end

          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end

        should 'set target assets appropriately' do
          assert @task.do_task(@workflows_controller, params)
        end
      end
    end

    context '#do_assign_requests_to_multiplexed_wells_task with new plate' do
      setup do
        PlateBarcode.stubs(:create).returns(MockBc.new('12345'))
        @purpose = create :plate_purpose
        @purpose_id = @purpose.id.to_s
        @well_array = %w(A1 B1 C1 D1 E1 F1 G1 G1)
      end

      shared

      context 'with no tag clashes' do
        setup do
          @tags = Array.new(8) { create :tag }
          @requests = (1..8).map do |i|
            r = create :pooled_cherrypick_request
            r.asset.aliquots.first.update_attributes!(tag: @tags[i])
            r
          end

          @well_array = %w(A1 B1 C1 D1 E1 F1 G1 H1)

          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end
        should 'set target assets appropriately' do
          assert_equal nil, @workflows_controller.flash[:error]
          assert @task.do_task(@workflows_controller, params), 'Task returned false'
          @requests.each_with_index do |r, _i|
            assert_equal request_location_hash[r.id.to_s], r.target_asset.map_description
            assert_equal @purpose.plates.last, r.target_asset.plate
            assert_equal @purpose, r.target_asset.plate.purpose
          end
        end
        should 'set the pick volume on the target_wells' do
          assert @task.do_task(@workflows_controller, params), 'Task returned false'
          @requests.each do |request|
            assert_equal 5, request.target_asset.get_picked_volume
          end
        end
      end

      context 'with identical samples' do
        setup do
          @tag = create :tag
          @sample = create :sample
          @requests = (1..8).map do |_i|
            r = create :pooled_cherrypick_request
            r.asset.aliquots.first.update_attributes!(tag: @tag, sample: @sample)
            r
          end

          @well_array = %w(A1 B1 C1 D1 E1 F1 G1 H1)
          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end
        should 'set target assets appropriately' do
          assert_equal nil, @workflows_controller.flash[:error]
          assert @task.do_task(@workflows_controller, params), 'Task returned false'
          @requests.each_with_index do |r, _i|
            assert_equal request_location_hash[r.id.to_s], r.target_asset.map_description
            assert_equal @purpose.plates.last, r.target_asset.plate
            assert_equal @purpose, r.target_asset.plate.purpose
          end
        end
      end
    end
  end
end
