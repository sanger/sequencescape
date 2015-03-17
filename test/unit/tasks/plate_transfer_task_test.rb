#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014 Genome Research Ltd.
require "test_helper"

class DummyWorkflowController < WorkflowsController
  attr_accessor :batch
  attr_accessor :flash

  def initialize
    @flash = {}
  end

  def current_user
    @current_user ||= Factory :user
  end
end

class PlateTransferTaskTest < ActiveSupport::TestCase
  context "PlateTransferHandler" do

    setup do
      @workflows_controller = DummyWorkflowController.new
      @task                 = Factory :plate_transfer_task
      @params               = "UNUSED_PARAMS"
      @batch                = Factory :batch
      @workflows_controller.batch = @batch
      @source_plate         = Factory :plate
      @source_plate.wells   = ['A1','B1','C1'].map do |loc|
        Factory(:well_with_sample_and_without_plate).tap do |w|
          w.map = Map.find_by_description_and_asset_size(loc,96)
          request = PacBioSamplePrepRequest.create!(
            :asset=>w,
            :submission=>Submission.create!(:user=>Factory(:user)),
            :target_asset=> Factory(:pac_bio_library_tube)
          )
          @batch.requests << request
        end
      end
    end

    context '#render_plate_transfer_task' do
      setup do
        plate_barcode = mock("plate barcode")
        plate_barcode.stubs(:barcode).returns("1234567")
        PlateBarcode.stubs(:create).returns(plate_barcode)
      end

      context 'when used for the first time' do

        setup do
          params = { :batch_id => @batch.id }
          @task.render_task(@workflows_controller, params)
        end

        should_change("Plate.count", :by => 1) { Plate.count }

        should_change("TransferRequest.count", :by => 6) { TransferRequest.count }

        should 'mimic the original layout' do
          @source_plate.wells.each do |w|
            assert_equal w.aliquots.map{|a| a.sample.name}, Plate.last.wells.located_at(w.map_description).first.aliquots.map{|a| a.sample.name}
          end
        end

        should 'create transfer requests between wells' do
          @source_plate.wells.each do |w|
            assert_equal w.requests_as_source.where_is_a?(TransferRequest).last.target_asset, Plate.last.wells.located_at(w.map_description).first
          end
        end

        should 'create transfer to the Library tubes' do
          @batch.requests.each do |r|
            w = r.asset
            assert_equal r.target_asset, Plate.last.wells.located_at(w.map_description).first.requests.first.target_asset
          end
        end

      end

      context 'when used subsequently' do

        setup do
          params = { :batch_id => @batch.id }
          @task.render_task(@workflows_controller, params)
          @task.render_task(@workflows_controller, params)
        end

        should_change("Plate.count", :by => 1) { Plate.count }

        should 'find the existing plate' do

        end

      end

      context 'when spanning multiple plates' do
        setup do
          plate_b = Factory :plate
          plate_b.wells << Factory(:well_with_sample_and_without_plate).tap do |w|
            w.map = Map.find_by_description_and_asset_size('A1',96)
            request = Factory :well_request, :asset => w, :target_asset => Factory(:pac_bio_library_tube)
            w.requests << request
            @batch.requests << request
          end
        end

        should 'raise an exception' do
          assert_raise Tasks::PlateTransferHandler::InvalidBatch do
            params = { :batch_id => @batch.id }
            @task.render_task(@workflows_controller, params)
          end
        end
      end

    end

    context "#do_plate_transfer_task" do
      setup do

        plate_barcode = mock("plate barcode")
        plate_barcode.stubs(:barcode).returns("1234567")
        PlateBarcode.stubs(:create).returns(plate_barcode)

        params = {:plate_transfer_task => {}, :batch_id => @batch.id}
        # @workflows_controller.batch = mock("Batch")

                  params = { :batch_id => @batch.id }
          @task.render_task(@workflows_controller, params)
          @task.do_task(@workflows_controller, params)
      end

      should 'pass the transfer requests' do
        assert_equal 'passed', @batch.requests.first.asset.requests.where_is_a?(TransferRequest).first.state
      end
    end

  end
end
