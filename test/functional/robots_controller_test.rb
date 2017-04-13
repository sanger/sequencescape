# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class RobotsControllerTest < ActionController::TestCase
  tests Admin::RobotsController

  context 'Robots' do
    setup do
      @user = FactoryGirl.create :user
      session[:user] = @user
      @robot = FactoryGirl.create :robot
    end
    should_require_login

    context '#index' do
      setup do
        get :index
      end
      should respond_with :success
      should_not set_flash
    end

    context '#new' do
      setup do
        get :new
      end
      should respond_with :success
      should_not set_flash
    end

    context '#create' do
      setup do
        @count = Robot.count
        post :create, robot: { name: 'newrobot', location: 'biglab' }
      end
      should 'increase number of robots' do
        assert_equal @count + 1, Robot.count
        assert_redirected_to admin_robot_path(assigns(:robot))
      end
      should set_flash.to('Robot was successfully created.')
    end

    context '#show' do
      setup do
        get :show, id: @robot.id
      end
      should respond_with :success
      should_not set_flash
    end

    context '#edit' do
      setup do
        get :edit, id: @robot.id
      end
      should respond_with :success
      should_not set_flash
    end

    context '#update' do
      setup do
        put :update, id: @robot.id, robot: { name: 'tecan' }
      end

      should 'update name' do
        assert_equal 'tecan', Robot.find(@robot.id).name
        assert_redirected_to admin_robot_path(assigns(:robot))
      end
      should set_flash.to('Robot was successfully updated.')
    end

    context '#destroy' do
      setup do
        @count = Robot.count
        delete :destroy, id: @robot.id
      end
      should 'delete robot' do
        assert_equal @count - 1, Robot.count
        assert_redirected_to admin_robots_path
      end
      should set_flash.to('Robot removed successfully')
    end
  end
end
