# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
require 'test_helper'
require 'qc_files_controller'

class QcFilesControllerTest < ActionController::TestCase
  context '#show' do
    setup do
      File.open("#{Rails.root}/test/data/190_tube_sample_info.xls") do |file|
        @asset = create(:sample_tube)
        @qc_file = QcFile.create(asset: @asset, uploaded_data: { tempfile: file, filename: 'example.xls' }, filename: 'example.xls')
      end

      @controller = QcFilesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create :user
      session[:user] = @user.id
    end

    should 'return the file' do
      get :show, id: @qc_file.id
      assert_response :success
      assert_equal 'application/excel', response.content_type
    end
  end
end
