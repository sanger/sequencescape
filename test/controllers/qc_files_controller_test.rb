# frozen_string_literal: true

require 'test_helper'
require 'qc_files_controller'

class QcFilesControllerTest < ActionController::TestCase
  context '#show' do
    setup do
      File.open(Rails.root.join('test/data/190_tube_sample_info.xls')) do |file|
        @asset = create(:sample_tube)
        @qc_file =
          QcFile.create(
            asset: @asset,
            uploaded_data: {
              tempfile: file,
              filename: 'example.xls'
            },
            filename: 'example.xls'
          )
      end

      @controller = QcFilesController.new
      @request = ActionController::TestRequest.create(@controller)
      @user = create :user
      session[:user] = @user.id
    end

    should 'return the file' do
      get :show, params: { id: @qc_file.id }
      assert_response :success
      assert_equal 'application/vnd.ms-excel', response.content_type
    end
  end
end
