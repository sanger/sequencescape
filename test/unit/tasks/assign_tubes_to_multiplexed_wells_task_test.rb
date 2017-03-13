# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

# TODO: See below
# Batch will need to avoid creating wells upfron (Don't test in here, its just a pre-requisite for this taks behaviour)
# Ensure request start still works without target asset
# PacBio plate should be created, go for one with all 96 wells
# Requests should be hooked up according to params
# Transfer of aliquots into target plate should probably be linked to batch pass (Will make editing layout easier)
# Finally need to check csv generation, make sure one cell per well works

class DummyWorkflowController < WorkflowsController
  attr_accessor :flash, :batch

  def initialize
    @flash = {}
  end
end

class AssignTubestoMultiplexedWellsTaskTest < ActiveSupport::TestCase
  context 'AssignTubesToMultiplexedWellsHandler' do
    setup do
      @workflows_controller = DummyWorkflowController.new
      @task                 = create :assign_tubes_to_multiplexed_wells_task
      @wells = mock('wells')
      @fake_plate = mock('plate', wells: @wells)
      @workflows_controller.stubs(:find_or_create_plate).returns(@fake_plate)

      @dest_wells = %w(A1 B1 C1 D1 E1 F1 G1)

      @mock_wells = @dest_wells.map { |loc| mock('well', map_description: loc) }
    end

    context '#do_assign_requests_to_multiplexed_wells_task' do
      setup do
          @params = {
            request_locations: {
              '1' => 'A1', '2' => 'B1', '3' => 'C1', '4' => 'D1', '5' => 'E1', '6' => 'F1', '7' => 'G1', '8' => 'G1'
            },
            commit: 'Next step',
            batch_id: '2',
            next_stage: 'true',
            workflow_id: '24',
            id: '2'
          }
      end
      context 'with no tag clashes' do
        setup do
          request_target = [:none, 0, 1, 2, 3, 4, 5, 6, 6]
          tag_hash = Hash.new { |h, i| h[i] = create :tag }
          @tags = [1, 2, 3, 4, 5, 5, 7, 8].map { |i| tag_hash[i] }
          @requests = (1..8).map do |i|
            asset = create :pac_bio_library_tube
            asset.aliquots.first.update_attributes!(tag: @tags[i - 1])
            mock("request_#{i}",
              asset: asset).tap do |request|
              request.expects(:target_asset=).with(@mock_wells[request_target[i]])
              request.expects(:save!)
              request.expects(:id).at_least_once.returns(i)
              request.expects(:shared_attributes).at_least_once.returns('match')
            end
          end
          @wells.expects(:located_at).with(%w(A1 B1 C1 D1 E1 F1 G1)).returns(@mock_wells)
          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end
        should 'set target assets appropriately' do
          assert @task.do_task(@workflows_controller, @params)
        end
      end

      context 'with tag clashes' do
        setup do
          tag_hash = Hash.new { |h, i| h[i] = create :tag }
          @tags = [1, 2, 3, 4, 5, 5, 6, 6].map { |i| tag_hash[i] }
          @requests = (1..8).map do |i|
            asset = create :pac_bio_library_tube
            asset.aliquots.first.update_attributes!(tag: @tags[i - 1])
            mock("request_#{i}",
              asset: asset).tap do |request|
              request.expects(:id).at_least_once.returns(i)
            end
          end
          @wells.expects(:located_at).with(%w(A1 B1 C1 D1 E1 F1 G1)).returns(@mock_wells)
          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end

        should 'return false' do
          assert !@task.do_task(@workflows_controller, @params)
        end

        should 'set a flash[:notice] for failure' do
          @task.do_task(@workflows_controller, @params)
          assert_not_nil @workflows_controller.flash[:error]
          assert_equal 'Duplicate tags in G1', @workflows_controller.flash[:error]
        end
      end

      context 'with incompatible attributes' do
        setup do
          tag_hash = Hash.new { |h, i| h[i] = create :tag }
          @tags = [1, 2, 3, 4, 5, 5, 7, 8].map { |i| tag_hash[i] }
          @requests = (1..8).map do |i|
            asset = create :pac_bio_library_tube
            asset.aliquots.first.update_attributes!(tag: @tags[i - 1])
            mock("request_#{i}",
              asset: asset).tap do |request|
              request.expects(:id).at_least_once.returns(i)
              request.expects(:shared_attributes).at_least_once.returns("clash#{i}")
            end
          end
          @wells.expects(:located_at).with(%w(A1 B1 C1 D1 E1 F1 G1)).returns(@mock_wells)
          @batch = mock('batch')
          @batch.stubs(:requests).returns(@requests)
          @workflows_controller.batch = @batch
        end

        should 'return false' do
          assert !@task.do_task(@workflows_controller, @params)
        end

        should 'set a flash[:notice] for failure' do
          @task.do_task(@workflows_controller, @params)
          assert_not_nil @workflows_controller.flash[:error]
          assert_equal 'Incompatible requests in G1', @workflows_controller.flash[:error]
        end
      end
    end
  end
end
