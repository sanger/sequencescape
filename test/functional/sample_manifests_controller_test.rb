#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.

require "test_helper"
require 'sdb/sample_manifests_controller'

class SampleManifestsControllerTest < ActionController::TestCase

  context "SampleManifestsController" do

    setup do
      @controller = Sdb::SampleManifestsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create :user
      @controller.stubs(:current_user).returns(@user)
    end

    context '#show' do
      setup do
        @sample_manifest = create :sample_manifest_with_samples
      end

      should "return expected sample manifest" do
        get :show, id: @sample_manifest.id
        assert_response :success
        assert_equal @sample_manifest, assigns(:sample_manifest)
        assert_equal @sample_manifest.samples, assigns(:samples)
      end

    end

    context '#new' do
      should "be a success" do
        get :new, type: "plate"
        assert_response :success
      end
    end

    context '#create' do
      should "send print request" do
        barcode = mock("barcode")
        barcode.stubs(:barcode).returns(23)
        PlateBarcode.stubs(:create).returns(barcode)
        study = create :study
        supplier = Supplier.new(name: 'test')
        supplier.save
        barcode_printer = BarcodePrinter.new(name: 'd304bc', barcode_printer_type_id: 1)
        barcode_printer.save

        RestClient.expects(:post)
        post :create, sample_manifest: {template: "1",
                                       study_id: study.id,
                                       supplier_id: supplier.id,
                                       count: "3",
                                       barcode_printer: barcode_printer.id,
                                       only_first_label: "0",
                                       asset_type: ""}
      end

    end

  end

end