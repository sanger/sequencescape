# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class AttachInfiniumBarcodeTest < TaskTestBase
  context 'Attach Infinium Barcode task' do
    setup do
      @workflow  = WorkflowsController.new
      @br        = create :batch_request
      @task      = create :attach_infinium_barcode_task
    end

    expected_partial('attach_infinium_barcode_batches')

    context '#render_task' do
      setup do
        params = {}
        @task.render_task(@workflow, params)
      end
    end

    context '#do_task' do
      setup do
        @pipeline       = create :pipeline
        @batch          = create :batch, pipeline: @pipeline
        @plate1 = create :plate
        @plate2 = create :plate
      end
      context 'with valid parameters' do
        setup do
          params = { barcodes: { (@plate1.id).to_s => '111', (@plate2.id).to_s => '222' } }
          @task.do_task(@workflow, params)
        end

        should 'set the infinium barcode on plate 1' do
          assert_equal '111', Plate.find(@plate1.id).infinium_barcode
        end

        should 'set the infinium barcode on plate 2' do
          assert_equal '222', Plate.find(@plate2.id).infinium_barcode
        end
      end
      context 'with plate that doesnt exist' do
        setup do
          params = { barcodes: { '99999' => '111' } }
          @returned_task_value = @task.do_task(@workflow, params)
        end

        should 'return false' do
          assert !@returned_task_value
        end
      end
    end
  end
end
