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

  end
  
end