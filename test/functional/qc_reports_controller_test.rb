#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"
require 'qc_reports_controller'

# Re-raise errors caught by the controller.
class QcReportsController; def rescue_action(e) raise e end; end

class QcReportsControllerTest < ActionController::TestCase
  context "QcReports controller" do
    setup do
      @controller = QcReportsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.env["HTTP_REFERER"] = '/'

      @user     = Factory :user
      @controller.stubs(:current_user).returns(@user)

      @study  = Factory :study
      @product = Factory :product
      @product_criteria = Factory :product_criteria, :product => @product
    end

    should_require_login(:index)

    context "#index" do
      setup do
        get :index, :study_id => @study.id
      end
      should_respond_with :success
      should_render_template :index
    end

    context "#create" do
      setup do
        @qc_report_count = QcReport.count
        post :create, :qc_report => { :study_id => @study.id, :product_id => @product.id }
      end
      should_respond_with :redirect
      should_set_the_flash_to('Your report has been requested and will be presented on this page when complete.')
      should_redirect_to('show') { "/qc_reports/#{QcReport.last.id}" }

      should 'create a qc report for the study and product' do
        assert_equal 1, QcReport.count - @qc_report_count
        assert_equal @study, QcReport.last.study
        assert_equal @product_criteria, QcReport.last.product_criteria
      end
    end

    context "#create without product" do
      setup do
        post :create, :qc_report => { :study_id => @study.id }
      end
      should_respond_with :redirect
      should_redirect_to('index') { "/" }
      should_set_the_flash_to('You must select a product')
    end
  end
end
