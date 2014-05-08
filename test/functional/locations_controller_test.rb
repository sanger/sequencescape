require "test_helper"
require 'locations_controller'

class LocationsControllerTest < ActionController::TestCase

  context "LocationsController" do
    setup do
      @controller = LocationsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @location  = Factory :location
      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end

      should_render_template :index
    end

    context "#show" do
      setup do
        get :show, :id => @location.id
      end

      should_render_template :show
    end

    context "#new" do
      setup do
        get :new
      end

      should "render new" do
        assert_response :success
      end
    end

    context "#create_Location" do
      setup do
        @old_count = Location.count
        post  :create, {}
      end

      should "render create_Location" do
        assert_equal @old_count+1, Location.count
        assert_redirected_to location_path(assigns(:location))
      end
    end

    context "#edit" do
      setup do
        get :edit, :id => @location.id
      end

      should "render edit" do
        assert_response :success
      end
    end

    context "#update_Location" do
      setup do
        put :update,
            :id => @location.id,
            :location => {}
      end

      should "render update Location" do
        assert_redirected_to location_path(assigns(:location))
      end
    end

    context "#destroy_Location" do
      setup do
        @old_count = Location.count
        delete :destroy, :id => @location.id
      end

      should "destroy given Locations" do
        assert_equal @old_count-1, Location.count
        assert_redirected_to locations_path
      end
    end
  end

end