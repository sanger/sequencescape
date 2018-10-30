require 'test_helper'
require 'admin/roles_controller'
module Admin
  class RolesControllerTest < ActionController::TestCase
    context 'Roles controller' do
      setup do
        @controller = Admin::RolesController.new
        @request    = ActionController::TestRequest.create(@controller)
      end

      should_require_login

      context 'with user' do
        setup do
          session[:user] = @user = create :user
        end

        resource_test('role', with_prefix: 'admin_', ignore_actions: %w(create destroy update edit), formats: ['html'])
      end
    end
  end
end
