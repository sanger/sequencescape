# frozen_string_literal: true

require 'test_helper'

class LabwareControllerTest < ActionController::TestCase
  setup do
    @controller = LabwareController.new
    @request = ActionController::TestRequest.create(@controller)
    @user = create(:admin, api_key: 'abc')
    session[:user] = @user.id
  end

  should_require_login

  context 'print requests' do
    attr_reader :barcode_printer

    setup do
      @user = create(:user)
      @controller.stubs(:current_user).returns(@user)
      @barcode_printer = create(:barcode_printer)
    end

    should '#print_assets should send print request' do
      asset = create(:child_plate)
      RestClient.expects(:post)
      post :print_assets, params: { printables: asset, printer: barcode_printer.name, id: asset.id.to_s }
    end
    should '#print_labels should send print request' do
      asset = create(:sample_tube)
      RestClient.expects(:post)
      post :print_labels,
           params: {
             printables: {
               asset.id.to_s => 'true'
             },
             printer: barcode_printer.name,
             id: asset.id.to_s
           }
    end
  end
end
