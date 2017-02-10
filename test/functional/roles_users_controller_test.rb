# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'samples_controller'

class Admin::Roles::UsersControllerTest < ActionController::TestCase
  context 'Admin::Roles::UsersControllercontroller' do
    setup do
      @controller = Admin::Roles::UsersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'user', parent: 'role',
              actions: ['index'],
              ignore_actions: ['show', 'create'],
              user: -> { user = FactoryGirl.create(:user); user.is_administrator; user },
              formats: ['html']
    )
  end
end
