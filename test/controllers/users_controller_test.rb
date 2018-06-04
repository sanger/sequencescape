
require 'test_helper'
require 'users_controller'

class UsersControllerTest < ActionController::TestCase
  context 'Users controller' do
    setup do
      @controller = UsersController.new
      @request    = ActionController::TestRequest.create(@controller)
    end

    should_require_login :edit, :show, :update, resource: 'user'

    # should only be able to see your own page
  end
end
