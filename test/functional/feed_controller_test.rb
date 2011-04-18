require "test_helper"
require 'feed_controller'

# Re-raise errors caught by the controller.
class FeedController; def rescue_action(e) raise e end; end

class FeedControllerTest < ActionController::TestCase
  context "Feed controller" do
    setup do
      @controller = FeedController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login :updates

    should "be missing" do
      @request.accept = "application/xml"
      get :updates
      assert_response :missing
    end

  end
end
