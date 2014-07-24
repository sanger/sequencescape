require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class Roles::UsersController; def rescue_action(e) raise e end; end

class Roles::UsersControllerTest < ActionController::TestCase
  context "Roles::UsersControllercontroller" do
    setup do
      @controller = Roles::UsersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'user', {
        :parent => 'role',
        :actions => ['index'],
        :ignore_actions =>['show','create'],
        :user => lambda { user = Factory(:user) ; user.is_administrator ; user },
        :formats => ['html']
      }
    )
  end
end
