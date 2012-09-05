require "test_helper"
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase
  context "Users controller" do
    setup do
      @controller = UsersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login :edit, :show, :update

    # should only be able to see your own page
  end

end
