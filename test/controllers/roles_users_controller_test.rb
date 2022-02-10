# frozen_string_literal: true

require 'test_helper'
require 'samples_controller'

module Admin
  module Roles
    class UsersControllerTest < ActionController::TestCase
      context 'Admin::Roles::UsersControllercontroller' do
        setup do
          @controller = Admin::Roles::UsersController.new
          @request = ActionController::TestRequest.create(@controller)
        end

        should_require_login(:index, resource: 'user', parent: 'role')

        test_unit_class.resource_test(
          'user',
          parent: 'role',
          actions: ['index'],
          ignore_actions: %w[show create],
          user: :admin,
          formats: ['html']
        )
      end
    end
  end
end
