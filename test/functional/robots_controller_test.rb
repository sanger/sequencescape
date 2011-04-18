require "test_helper"

class RobotsControllerTest < ActionController::TestCase
  tests Admin::RobotsController

  context "Robots" do
    setup do
      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @robot  = Factory :robot
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#new" do
      setup do
        get :new
      end
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#create" do
      setup do
        @count = Robot.count
        post :create, :robot => {:name => "newrobot", :location=>"biglab" }
      end
      should "increase number of robots" do
        assert_equal @count+1, Robot.count
        assert_redirected_to robot_path(assigns(:robot))
      end
      should_set_the_flash_to "Robot was successfully created."
    end

    context "#show" do
      setup do
        get :show, :id => @robot.id
      end
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#edit" do
      setup do
        get :edit, :id => @robot.id
      end
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#update" do
      setup do
        put :update, :id => @robot.id, :robot => {:name => "tecan"}
      end

      should "update name" do
        assert_equal "tecan", Robot.find(@robot.id).name
        assert_redirected_to robot_path(assigns(:robot))
      end
      should_set_the_flash_to "Robot was successfully updated."
    end

    context "#destroy" do
      setup do
        @count = Robot.count
        delete :destroy, :id => @robot.id
      end
      should "delete robot" do
        assert_equal @count-1, Robot.count
        assert_redirected_to robots_path
      end
      should_set_the_flash_to ="Robot removed successfully"
    end

  end
end
