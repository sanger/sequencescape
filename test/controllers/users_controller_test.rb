# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
