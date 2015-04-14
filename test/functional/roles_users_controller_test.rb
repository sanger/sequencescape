#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
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
