# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  context 'Admin controller' do
    setup do
      @controller = AdminController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context 'admin frontpage' do
      setup do
        session[:user] = @user = create :admin
      end

      context '#index' do
        setup do
          get :index
        end
        should respond_with :success
        should render_template :index
      end

      context '#filter' do
        setup do
          get :filter
        end
        should respond_with :success
        should render_template 'admin/users/_users'
      end

      context '#filter with query' do
        setup do
          get :filter, q: 'abc123'
        end
        should respond_with :success
        should render_template 'admin/users/_users'
      end
    end
  end
end
