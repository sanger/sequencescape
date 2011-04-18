require "test_helper"
require 'implements_controller'

class ImplementsControllerTest < ActionController::TestCase

  context "#Implement controller" do
    setup do
      @controller = ImplementsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = Factory :admin
      @controller.stubs(:current_user).returns(@user)
      @implement = Factory :implement
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end
      
      should "get index" do
        assert_response :success
        assert assigns(:implements)
      end
    end
   
    context "#show" do
      setup do
       
        get :show, :id => @implement.id
      end
      
      should "show_asset" do
        assert_response :success
      end
    end
    
    context "#edit" do
      setup do
        get :edit, :id => @implement.id
      end
      
      should "get edit" do
        assert_response :success
      end
    end
    
    
    context "#update" do
      setup do
        put :update, :id => @implement.id, :implement => { }
      end
      should "update implement" do
        assert_redirected_to implement_path(assigns(:implement))
      end
    end
    
    context "#destroy" do
      setup do
        @old_count = Implement.count
        delete :destroy, :id => @implement.id
      end
      
      should "destroy" do
        assert_equal @old_count-1, Implement.count
        assert_redirected_to implements_path
      end
    end
    
    context "#print_labels" do
      setup do
        get :print_labels
      end
      
      should "get print_labels" do
        assert_response :success
        assert assigns(:implements)
      end
    end
    
    

  end
end
