require "test_helper"
require 'annotations_controller'

# Re-raise errors caught by the controller.
class AnnotationsController; def rescue_action(e) raise e end; end

class AnnotationsControllerTest < ActionController::TestCase
  context "Annotations controller" do
    setup do
      @controller = AnnotationsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      
      @user = Factory :user
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)
    end

    should "show be missing" do
      get :show
      assert_response 410
    end

    should "create be missing" do
      get :create
      assert_response 410
    end

  end
end
