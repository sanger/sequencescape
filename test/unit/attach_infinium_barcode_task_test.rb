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
          params = { barcodes: { (@plate1.id).to_s => 'WG4000211-DNA', (@plate2.id).to_s => 'WG4000212-DNA' } }
          @task.do_task(@workflow, params)
        end

        should 'set the infinium barcode on plate 1' do
          assert_equal 'WG4000211-DNA', Plate.find(@plate1.id).infinium_barcode
        end

        should 'set the infinium barcode on plate 2' do
          assert_equal 'WG4000212-DNA', Plate.find(@plate2.id).infinium_barcode
        end
      end
      context 'with plate that doesnt exist' do
        setup do
          params = { barcodes: { '99999' => '111' } }
          @returned_task_value = @task.do_task(@workflow, params)
        end

        should 'return false' do
          assert_not @returned_task_value
        end
      end
    end
  end
end
