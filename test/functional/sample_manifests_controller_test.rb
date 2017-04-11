# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

require 'test_helper'
require 'sdb/sample_manifests_controller'

class SampleManifestsControllerTest < ActionController::TestCase
  context 'SampleManifestsController' do
    setup do
      @controller = Sdb::SampleManifestsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create :user
      session[:user] = @user.id

      SampleManifestExcel.configure do |config|
        config.folder = File.join('test', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    context '#show' do
      setup do
        @sample_manifest = create :sample_manifest_with_samples
      end

      should 'return expected sample manifest' do
        get :show, id: @sample_manifest.id
        assert_response :success
        assert_equal @sample_manifest, assigns(:sample_manifest)
        assert_equal @sample_manifest.samples, assigns(:samples)
      end
    end

    context '#new' do
      should 'be a success' do
        get :new, type: 'plate'
        assert_response :success
      end
    end

    context '#create' do
      should 'send print request' do
        barcode = mock('barcode')
        barcode.stubs(:barcode).returns(23)
        PlateBarcode.stubs(:create).returns(barcode)
        study = create :study
        supplier = Supplier.new(name: 'test')
        supplier.save

        barcode_printer = create :barcode_printer
        LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])

        RestClient.expects(:post)
        post :create, sample_manifest: { template: 'plate_default',
                                         study_id: study.id,
                                         supplier_id: supplier.id,
                                         count: '3',
                                         barcode_printer: barcode_printer.name,
                                         only_first_label: '0',
                                         asset_type: '' }
        RestClient.expects(:post)
        post :create, sample_manifest: { template: 'tube_default',
                                         study_id: study.id,
                                         supplier_id: supplier.id,
                                         count: '3',
                                         barcode_printer: barcode_printer.name,
                                         only_first_label: '0',
                                         asset_type: '' }
      end
    end
  end
end
