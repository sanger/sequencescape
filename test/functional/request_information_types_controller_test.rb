require "test_helper"
require 'request_information_types_controller'

class RequestInformationTypesControllerTest < ActionController::TestCase
  
  context "RequestInformationTypesController" do
    setup do
      @controller = RequestInformationTypesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request_information_type       = Factory :request_information_type
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
        get :show, :id => @request_information_type.id
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
    
    context "#create_request_information_type" do
      setup do
        @old_count = RequestInformationType.count
        post  :create, {:name => "asdf"}
      end
      
      should "render create" do
        assert_equal @old_count+1, RequestInformationType.count
        assert_redirected_to request_information_type_path(assigns(:request_information_type))
      end
    end
    
    context "#edit" do
      setup do
        get :edit, :id => @request_information_type.id
      end
      
      should "render edit" do
        assert_response :success
      end
    end
    
    context "#update_task" do
      setup do
        put :update, 
            :id => @request_information_type.id, 
            :request_information_type => {}
      end
      
      should "render update request_information_type" do
        assert_redirected_to request_information_type_path(assigns(:request_information_type))
      end
    end
    
    context "#destroy_task" do
      setup do
        @old_count = RequestInformationType.count
        delete :destroy, :id => @request_information_type.id
      end
      
      should "destroy given RequestInformationTypes" do
        assert_equal @old_count-1, RequestInformationType.count
        assert_redirected_to request_information_types_path
      end
    end
  end
  
end