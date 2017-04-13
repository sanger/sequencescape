# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

require 'test_helper'

class AssetsControllerTest < ActionController::TestCase
  setup do
    @controller = AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = create :admin, api_key: 'abc'
    session[:user] = @user.id
  end

  should_require_login

  context '#create a new asset with JSON input' do
    setup do
      @asset_count = Asset.count

      @barcode = FactoryGirl.generate :sanger_barcode

      @json_data = json_new_asset(@barcode)

      @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
      post :create, ActiveSupport::JSON.decode(@json_data)
    end

    should set_flash.to(/Asset was successfully created/)

     should 'change Asset.count by 1' do
       assert_equal 1, Asset.count - @asset_count, 'Expected Asset.count to change by 1'
     end
  end

  context 'an asset_id' do
    setup do
      @asset = create :sample_tube
      @location = create :location
      put :update, id: @asset.id, asset: { location_id: @location.id }
    end
    should 'be updateable' do
      assert_equal @location, @asset.location
    end
  end

  context 'create request with JSON input' do
    setup do
      @submission_count = Submission.count
      @asset = create(:sample_tube)
      @sample = @asset.primary_aliquot.sample

      @study = create :study
      @project = create :project, enforce_quotas: true
      @request_type = create :request_type
      @workflow = create :submission_workflow
      @json_data = valid_json_create_request(@asset, @request_type, @study, @project)

      @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
      post :create_request, ActiveSupport::JSON.decode(@json_data)
    end

    should 'change Submission.count by 1' do
      assert_equal 1, Submission.count - @submission_count, 'Expected Submission.count to change by 1'
    end
    should 'set a priority' do
      assert_equal(3, Submission.last.priority)
    end
  end

  context 'print requests' do
    attr_reader :barcode_printer

    setup do
      @user = create :user
      @controller.stubs(:current_user).returns(@user)
      @barcode_printer = create :barcode_printer
      LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    end

    should '#print_assets should send print request' do
      asset = create :child_plate
      RestClient.expects(:post)
      post :print_assets, printables: asset, printer: barcode_printer.name, id: (asset.id).to_s
    end
    should '#print_labels should send print request' do
      asset = create :sample_tube
      RestClient.expects(:post)
      post :print_labels, printables: { (asset.id).to_s => 'true' }, printer: barcode_printer.name, id: (asset.id).to_s
    end
  end

  def valid_json_create_request(asset, request_type, study, project)
    %Q{
      {
        "api_version": "#{RELEASE.api_version}",
        "api_key": "abc",
        "study_id": "#{study.id}",
        "project_id": "#{project.id}",
        "request_type_id": "#{request_type.id}",
        "count": 3,
        "priority": 3,
        "comments": "This is a request",
        "id": "#{asset.id}",
        "request": {
          "properties": {
            "library_type": "Standard",
            "fragment_size_required_from": 100,
            "fragment_size_required_to": 500,
            "read_length": 108
          }
        }
      }
    }
  end

  def json_new_asset(barcode)
    # /assets
    %Q{
      {
        "api_version": "#{RELEASE.api_version}",
        "api_key": "abc",
        "asset": {
          "sti_type": "SampleTube",
          "barcode": "#{barcode}",
          "label": "SampleTube"
        }
      }
    }
  end
end
