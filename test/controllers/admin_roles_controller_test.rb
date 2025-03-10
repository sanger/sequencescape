# frozen_string_literal: true

require 'test_helper'

module Admin
  class RolesControllerTest < ActionController::TestCase
    context 'Roles controller' do
      setup do
        @controller = Admin::RolesController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login

      context 'with user' do
        setup { session[:user] = @user = create(:admin) }

        resource_test(
          'role',
          with_prefix: 'admin_',
          ignore_actions: %w[create destroy update edit],
          formats: ['html'],
          user: :admin
        )
      end
    end
  end
end
