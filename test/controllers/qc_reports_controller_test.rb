# frozen_string_literal: true

require 'test_helper'

class QcReportsControllerTest < ActionController::TestCase
  context 'QcReports controller' do
    setup do
      @controller = QcReportsController.new
      @request = ActionController::TestRequest.create(@controller)
      @request.env['HTTP_REFERER'] = '/'

      @user = create(:user)
      session[:user] = @user.id
      @study = create(:study)
      @product = create(:product)
      @product_criteria = create(:product_criteria, product: @product)
    end

    should_require_login(:index)

    context '#index' do
      setup { get :index, params: { study_id: @study.id } }
      should respond_with :success
      should render_template :index
    end

    context '#create' do
      setup do
        @qc_report_count = QcReport.count
        post :create, params: { qc_report: { study_id: @study.id, product_id: @product.id } }
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
      setup { post :create, params: { qc_report: { study_id: @study.id } } }
      should respond_with :redirect
      should redirect_to('index') { '/' }
      should set_flash.to('You must select a product')
    end
  end
end
