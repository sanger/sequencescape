require "test_helper"

class RequestTypesControllerTest < ActionController::TestCase
  context "RequestTypes controller" do
    setup do
      @controller = RequestTypesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    resource_test('request_type', {:formats => ['html'],:ignore_actions =>['show','create'], :user => :admin})
  end
end
