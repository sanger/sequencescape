# frozen_string_literal: true

require 'test_helper'

class RobotsControllerTest < ActionController::TestCase
  tests Admin::RobotsController

  context 'Robots' do
    setup do
      @user = FactoryBot.create(:admin)
      session[:user] = @user
      @robot = FactoryBot.create(:robot)
    end
    should_require_login

    context '#index' do
      setup { get :index }
      should respond_with :success
      should_not set_flash
    end

    context '#new' do
      setup { get :new }
      should respond_with :success
      should_not set_flash
    end

    context '#create' do
      setup do
        @count = Robot.count
        post :create, params: { robot: { name: 'newrobot', location: 'biglab' } }
      end
      should 'increase number of robots' do
        assert_equal @count + 1, Robot.count
        assert_redirected_to admin_robot_path(assigns(:robot))
      end
      should set_flash.to('Robot was successfully created.')
    end

    context '#show' do
      setup { get :show, params: { id: @robot.id } }
      should respond_with :success
      should_not set_flash
    end

    context '#edit' do
      setup { get :edit, params: { id: @robot.id } }
      should respond_with :success
      should_not set_flash
    end

    context '#update' do
      setup { put :update, params: { id: @robot.id, robot: { name: 'tecan' } } }

      should 'update name' do
        assert_equal 'tecan', Robot.find(@robot.id).name
        assert_redirected_to admin_robot_path(assigns(:robot))
      end
      should set_flash.to('Robot was successfully updated.')
    end

    context '#destroy' do
      setup do
        @count = Robot.count
        delete :destroy, params: { id: @robot.id }
      end
      should 'delete robot' do
        assert_equal @count - 1, Robot.count
        assert_redirected_to admin_robots_path
      end
      should set_flash.to('Robot removed successfully')
    end
  end
end
