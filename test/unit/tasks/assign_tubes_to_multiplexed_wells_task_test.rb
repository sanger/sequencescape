#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"


# TODO:
# Batch will need to avoid creating wells upfron (Don't test in here, its just a pre-requisite for this taks behaviour)
# Ensure request start still works without target asset
# PacBio plate should be created, go for one with all 96 wells
# Requests should be hooked up according to params
# Transfer of aliquots into target plate should probably be linked to batch pass (Will make editing layout easier)
# Finally need to check csv generation, make sure one cell per well works

class DummyWorkflowController < WorkflowsController

  attr_accessor :flash

  def initialize
    @flash = {}
  end
end

class AssignTubestoMultiplexedWellsTaskTest < ActiveSupport::TestCase
  context "AssignTubesToMultiplexedWellsHandler" do
    setup do
      @workflows_controller = DummyWorkflowController.new
      @task                 = Factory :assign_tubes_to_multiplexed_wells_task
    end

    context "#do_assign_tubes_to_multiplexed_wells_task" do
      setup do
      end
      context "with no tag clashes" do
        setup do
          @params = {
            :request_locations=>{
              "1"=>"A1",
              "2"=>"B1",
              "3"=>"C1",
              "4"=>"D1",
              "5"=>"E1",
              "6"=>"F1",
              "7"=>"G1",
              "8"=>"G1"
            },
            :commit =>"Next step",
            :batch_id =>"2",
            :next_stage =>"true",
            :workflow_id =>"24",
            :id=>"2"
          }
        end
        should "set target assets appropriately" do
          assert true
        end
      end

      context "with tag clashes" do
        setup do
        end

        should "return false" do
        end

        should "set a flash[:notice] for failure" do
          assert_not_nil @workflows_controller.flash[:error]
        end
      end
    end

  end
end
