require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class Admin::UsersController; def rescue_action(e) raise e end; end

class Admin::UsersControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Admin::UsersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'user', {
        :ignore_actions => ['update'],
        :actions => ['show','edit','index'],
        :formats => ['html'],
        :defaults => {:login =>"abc1234"},
        :user => lambda { user = Factory(:user) ; user.is_administrator ; user },

        # Setup needed because 'edit' assumes presence of at least one Study and Project
        :setup => lambda { Factory(:study) ; Factory(:project) }
      }
    )

    context "#filter" do
      setup do
        @user = Factory :user
        @admin = Factory :admin
        @controller.stubs(:current_user).returns(@admin)
        @controller.stubs(:logged_in?).returns(@admin)

        @user_to_find = Factory :user, :first_name => "Some", :last_name => "Body", :login => "sb1"
        @another_user = Factory :user, :first_name => "No", :last_name =>"One", :login => "no1"

      end

      should "find a user based on name" do
        post :filter, :q => "Some"

        @users = assigns(:users)
        assert_equal @user_to_find, @users.first
      end

      should "find a user based on login" do
        post :filter, :q => "sb"

        @users = assigns(:users)
        assert_equal @user_to_find, @users.first
      end

      should "find multiple users with shared characters in their logins" do
        post :filter, :q => "1"

        @users = assigns(:users)
        assert @users.detect{ |u| u == @user_to_find }
        assert @users.detect{ |u| u == @another_user }
      end

      should "find multiple users with shared characters in their names" do
        post :filter, :q => "o"

        @users = assigns(:users)
        assert @users.detect{ |u| u == @user_to_find }
        assert @users.detect{ |u| u == @another_user }
      end
    end
  end
end
