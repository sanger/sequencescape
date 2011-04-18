require "test_helper"
require 'pipelines_controller'

class PipelinesControllerTest < ActionController::TestCase
  context "Pipelines controller" do
    setup do
      @controller = PipelinesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end

      should_respond_with :success
    end

    context "#user is administrator" do
      setup do
        admin = Factory :role, :name => "administrator"
        @user.roles << admin
      end

      context "#new" do
        setup do
          get :new
        end

        should_respond_with :success
      end

      context "#edit" do
        setup do
          @pipeline = Factory :pipeline
          get :edit, :id => @pipeline.id.to_s
        end

        should_respond_with :success
      end
    end

    context "#user is not administrator" do
      setup do
        admin = Factory :role, :name => "follower"
        @user.roles << admin
      end

      context "#new" do
        setup do
          get :new
        end

        should_respond_with :redirect
      end

      context "#edit" do
        setup do
          @pipeline = Factory :pipeline
          get :edit, :id => @pipeline.id.to_s
        end

        should_respond_with :redirect
      end
      
      context "#create" do
        setup do
          @pipeline = Factory :pipeline
          get :create, :id => @pipeline.id.to_s
        end
        
        should_redirect_to("index") {pipelines_path}
      end
    end

    context "#batches" do
      setup do
        @pipeline = Factory :pipeline
      end
      context "without any pipeline batches" do
        setup do
          get :batches, :id => @pipeline.id.to_s
        end

        should_respond_with :success
      end

      context "with 1 batch" do
        setup do
          Factory :batch, :pipeline => @pipeline
          get :batches, :id => @pipeline.id.to_s
        end

        should_respond_with :success
      end
    end

    context "#show" do
      setup do
        @pipeline = Factory :pipeline
        get :show, :id => @pipeline
      end

      should_respond_with :success
      context "and no batches" do
        setup do
          @pipeline = Factory :pipeline
          get :show, :id => @pipeline
        end

        should_respond_with :success
      end
    end

    context "#setup_inbox" do
      setup do
        @pipeline = Factory :pipeline
        get :setup_inbox, :id => @pipeline.id.to_s
      end

      should_respond_with :success
    end

    context "#training_batch" do
      setup do
        @pipeline = Factory :pipeline
        get :training_batch, :id => @pipeline.id.to_s
      end

      should_respond_with :success
    end

    context "#activate" do
      setup do
        @pipeline = Factory :pipeline
        get :activate, :id => @pipeline.id.to_s
      end

      should_respond_with :redirect
    end

    context "#deactivate" do
      setup do
        @pipeline = Factory :pipeline
        get :deactivate, :id => @pipeline.id.to_s
      end

      should_respond_with :redirect
    end

    context "#destroy" do
      setup do
        @pipeline = Factory :pipeline
        get :destroy, :id => @pipeline.id.to_s
      end

      should_respond_with :redirect
    end
  end
end
