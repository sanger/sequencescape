# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'admin/roles_controller'

class Admin::RolesControllerTest < ActionController::TestCase
  context 'Roles controller' do
    setup do
      @controller = Admin::RolesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
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
