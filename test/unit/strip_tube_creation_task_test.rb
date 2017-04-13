# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class StripTubeCreationTest < TaskTestBase
  class DummyWorkflowController < WorkflowsController
    attr_accessor :batch, :pipeline
    attr_accessor :flash, :tubes_requested, :tubes_available, :options

    def initialize(pipeline)
      @pipeline = pipeline
      @flash = {}
    end

    def current_user
      @current_user ||= create :user
    end
  end

  context 'StripTubeCreation task' do
    setup do
      @workflow_c = DummyWorkflowController.new(@pipeline)
      @pipeline       = create :pipeline
      @batch          = create :batch, pipeline: @pipeline
      @task           = create :strip_tube_creation_task, workflow: @pipeline.workflow
      @task.descriptors <<
        Descriptor.new(name: 'test', selection: [1, 2, 4, 6, 12], key: 'strips_to_create') <<
        Descriptor.new(name: 'test2', value: 'Strip Tube Purpose', key: 'strip_tube_purpose')
      @plate = create :plate_for_strip_tubes

      @request_type = create :well_request_type
      @plate.wells.in_plate_column(1, 96).each do |well|
        2.times { @batch.requests << build(:request_without_assets, asset: well, target_asset: nil, request_type: @request_type) }
      end
      @pipeline.request_types << @request_type
    end

    context '#render_task' do
      setup do
        @workflow_c.batch = @batch
        params = {}
        @task.render_task(@workflow_c, params)
      end

      should 'set expected variables' do
        assert_equal 2,     @workflow_c.tubes_requested
        assert_equal 2,     @workflow_c.tubes_available
        assert_equal [1, 2], @workflow_c.options
      end
    end

    context '#do_task with all tubes' do
      setup do
        @workflow_c.batch = @batch
        params = { 'tubes_to_create' => 2, 'source_plate_barcode' => @plate.ean13_barcode }
        @before = StripTube.count
        @task.do_task(@workflow_c, params)
      end

      should 'create 2 strip tubes' do
        assert_equal 2, StripTube.count - @before
        assert_equal 2, @plate.wells.located_at('B1').first.requests.count
        assert_equal 'S2', @plate.wells.located_at('B1').first.requests.first.target_asset.map_description
      end

      should 'start all requests' do
        assert_equal 16, @batch.requests.count
        # assert @batch.requests.all?(&:started?)
      end
    end

    context '#do_task with incorrect barcode' do
      setup do
        @workflow_c.batch = @batch
        params = { 'tubes_to_create' => 2, 'source_plate_barcode' => 'not a barcode' }
        @before = StripTube.count
        @return = @task.do_task(@workflow_c, params)
      end

      should 'not create 2 strip tubes' do
        assert_equal 0, StripTube.count - @before
      end

      should 'return false' do
        assert_equal false, @return
        assert_equal "'not a barcode' is not the correct plate for this batch.", @workflow_c.flash[:error]
      end
    end

    context '#do_task with remaining tubes' do
      setup do
        @workflow_c.batch = @batch
        params = { 'tubes_to_create' => 1, 'source_plate_barcode' => @plate.ean13_barcode }
        @before = StripTube.count
        @task.do_task(@workflow_c, params)
        @rs = @batch.requests
      end

      should 'create 1 strip tubes' do
        assert_equal 1, StripTube.count - @before
      end

      should 'remove some requests from the batch' do
        @batch.reload
        assert_equal 8, @batch.requests.count
      end
    end
  end
end
