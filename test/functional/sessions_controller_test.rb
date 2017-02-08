# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'sessions_controller'

class SessionsControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = FactoryGirl.create(:user, login: 'john', email: 'john@beatles.com',
                                      password: 'test', password_confirmation: 'test',
                                      created_at: 5.days.ago.to_s)
  end

  def test_should_login_and_redirect
    post :login, login: 'john', password: 'test'
    assert session[:user]
    # assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, login: 'john', password: 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_logout
    login_as @user
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end
end
