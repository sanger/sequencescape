require "test_helper"
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user       = Factory(:user, :login => "john", :email => "john@beatles.com",
      :salt => "7e3041ebc2fc05a40c60028e2c4901a81035d3cd",
      :crypted_password => "00742970dc9e6319f8019fd54864d3ea740f04b1", # test
      :created_at => 5.days.ago.to_s)
  end

  def test_should_login_and_redirect
    post :login, :login => 'john', :password => 'test'
    assert session[:user]
    # assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'john', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_logout
    login_as @user
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  protected
    def create_user(options = {})
      post :signup, :user => { :login => 'ringo', :email => 'ringo@example.com',
        :password => 'ringo', :password_confirmation => 'ringo' }.merge(options)
    end

    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end

    def cookie_for(user)
      auth_token user.remember_token
    end
end
