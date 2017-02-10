# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require 'test_helper'
require 'qc_reports_controller'

class QcReportsControllerTest < ActionController::TestCase
  context 'QcReports controller' do
    setup do
      @controller = QcReportsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.env['HTTP_REFERER'] = '/'

      @user = create :user
      session[:user] = @user.id
      @study = create :study
      @product = create :product
      @product_criteria = create :product_criteria, product: @product
    end

    should_require_login(:index)

    context '#index' do
      setup do
        get :index, study_id: @study.id
      end
      should respond_with :success
      should render_template :index
    end

    context '#create' do
      setup do
        @qc_report_count = QcReport.count
        post :create, qc_report: { study_id: @study.id, product_id: @product.id }
      end
      should respond_with :redirect
      should set_flash.to('Your report has been requested and will be presented on this page when complete.')
      should redirect_to('show') { "/qc_reports/#{QcReport.last.report_identifier}" }

      should 'create a qc report for the study and product' do
        assert_equal 1, QcReport.count - @qc_report_count
        assert_equal @study, QcReport.last.study
        assert_equal @product_criteria, QcReport.last.product_criteria
      end
    end

    context '#create without product' do
      setup do
        post :create, qc_report: { study_id: @study.id }
      end
      should respond_with :redirect
      should redirect_to('index') { '/' }
      should set_flash.to('You must select a product')
    end
  end
end
