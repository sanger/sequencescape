require "test_helper"
require 'roles_controller'

# Re-raise errors caught by the controller.
class RolesController; def rescue_action(e) raise e end; end

class RolesControllerTest < ActionController::TestCase
  context "Roles controller" do
    setup do
      @controller = RolesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @user = Factory :user
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)

    end

    should_require_login

    resource_test('role', :ignore_actions =>['show', 'create'], :formats => ['html'])
  end
end
