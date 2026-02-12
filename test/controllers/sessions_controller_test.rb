# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  def setup
    @controller = SessionsController.new
    @request = ActionController::TestRequest.create(@controller)
    @user =
      FactoryBot.create(
        :user,
        login: 'john',
        email: 'john@beatles.com',
        password: 'test',
        password_confirmation: 'test',
        created_at: 5.days.ago.to_s
      )
  end

  def test_should_login_and_redirect
    post :login, params: { login: 'john', password: 'test' }

    assert session[:user]
    # assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, params: { login: 'john', password: 'bad password' }

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
