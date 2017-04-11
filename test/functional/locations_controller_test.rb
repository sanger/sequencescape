# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'locations_controller'

class LocationsControllerTest < ActionController::TestCase
  context 'LocationsController' do
    setup do
      @controller = LocationsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @location = FactoryGirl.create :location
      @user = FactoryGirl.create :user
      session[:user] = @user.id
    end
    should_require_login

    context '#index' do
      setup do
        get :index
      end

      should render_template :index
    end

    context '#show' do
      setup do
        get :show, id: @location.id
      end

      should render_template :show
    end

    context '#new' do
      setup do
        get :new
      end

      should 'render new' do
        assert_response :success
      end
    end

    context '#create_Location' do
      setup do
        @old_count = Location.count
        post :create, {}
      end

      should 'render create_Location' do
        assert_equal @old_count + 1, Location.count
        assert_redirected_to location_path(assigns(:location))
      end
    end

    context '#edit' do
      setup do
        get :edit, id: @location.id
      end

      should 'render edit' do
        assert_response :success
      end
    end

    context '#update_Location' do
      setup do
        put :update,
            id: @location.id,
            location: {}
      end

      should 'render update Location' do
        assert_redirected_to location_path(assigns(:location))
      end
    end

    context '#destroy_Location' do
      setup do
        @old_count = Location.count
        delete :destroy, id: @location.id
      end

      should 'destroy given Locations' do
        assert_equal @old_count - 1, Location.count
        assert_redirected_to locations_path
      end
    end
  end
end
