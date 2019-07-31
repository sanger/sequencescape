# frozen_string_literal: true

require 'test_helper'
require 'sdb/sample_manifests_controller'

class SampleManifestsControllerTest < ActionController::TestCase
  context 'SampleManifestsController' do
    setup do
      @controller = Sdb::SampleManifestsController.new
      @request    = ActionController::TestRequest.create(@controller)
      @user       = create :user
      session[:user] = @user.id

      SampleManifestExcel.configure do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    context '#show' do
      setup do
        @sample_manifest = create :sample_manifest_with_samples
      end

      should 'return expected sample manifest' do
        get :show, params: { id: @sample_manifest.id }
        assert_response :success
        assert_equal @sample_manifest, assigns(:sample_manifest)
        assert_equal @sample_manifest.samples, assigns(:samples)
      end
    end

    context '#new' do
      should 'be a success' do
        get :new, params: { type: 'plate' }
        assert_response :success
      end
    end

    context '#create' do
      should 'send print request' do
        PlateBarcode.stubs(:create).returns(
          stub(barcode: 23),
          stub(barcode: 24),
          stub(barcode: 25),
          stub(barcode: 26),
          stub(barcode: 27)
        )
        study = create :study
        supplier = Supplier.new(name: 'test')
        supplier.save

        barcode_printer = create :barcode_printer
        LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])

        RestClient.expects(:post)
        post :create, params: { sample_manifest: { template: 'plate_default',
                                                   study_id: study.id,
                                                   supplier_id: supplier.id,
                                                   count: '2',
                                                   barcode_printer: barcode_printer.name,
                                                   only_first_label: '0',
                                                   asset_type: '' } }
        RestClient.expects(:post)
        post :create, params: { sample_manifest: { template: 'tube_default',
                                                   study_id: study.id,
                                                   supplier_id: supplier.id,
                                                   purpose_id: Tube::Purpose.standard_sample_tube.id,
                                                   count: '2',
                                                   barcode_printer: barcode_printer.name,
                                                   only_first_label: '0',
                                                   asset_type: '' } }
      end
    end
  end
end
