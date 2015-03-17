#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
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
