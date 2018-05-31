# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'samples_controller'

module Admin
  module Roles
    class UsersControllerTest < ActionController::TestCase
      context 'Admin::Roles::UsersControllercontroller' do
        setup do
          @controller = Admin::Roles::UsersController.new
          @request    = ActionController::TestRequest.create(@controller)
        end

        should_require_login(:index, resource: 'user', parent: 'role')

        resource_test(
          'user', parent: 'role',
                  actions: ['index'],
                  ignore_actions: ['show', 'create'],
                  user: -> { FactoryBot.create(:admin) },
                  formats: ['html']
        )
      end
    end
  end
end
