require "test_helper"

class WorkflowsController
  attr_writer :batch
end

class AttachInfiniumBarcodeTest < TaskTestBase
  context "Attach Infinium Barcode task" do
    setup do
      @workflow  = WorkflowsController.new
      @br        = Factory :batch_request
      @task      = Factory :attach_infinium_barcode_task
    end

    expected_partial("attach_infinium_barcode_batches")

    context "#render_task" do
      setup do
        @workflow.batch = @br.batch
        params = {}
        @task.render_task(@workflow, params)
      end
    end

    context "#do_task" do
      setup do
        @pipeline       = Factory :pipeline, :request_type_id => 1
        @batch          = Factory :batch, :pipeline => @pipeline
        @plate1 = Factory :plate
        @plate2 = Factory :plate
        @workflow.batch = @batch
      end
      context "with valid parameters" do
        setup do
          params = { :barcodes => {"#{@plate1.id}" => "111", "#{@plate2.id}" => "222"}}
          @task.do_task(@workflow, params)
        end

        should 'set the infinium barcode on plate 1' do
          assert_equal "111", Plate.find(@plate1.id).infinium_barcode
        end

        should 'set the infinium barcode on plate 2' do
          assert_equal "222", Plate.find(@plate2.id).infinium_barcode
        end
      end
      context "with plate that doesnt exist" do
        setup do
          params = { :barcodes => {"99999" => "111"}}
          @returned_task_value = @task.do_task(@workflow, params)
        end

        should "return false" do
          assert ! @returned_task_value
        end
      end
    end
  end
end
