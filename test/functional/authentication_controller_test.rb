require "test_helper"

# Re-raise errors caught by the controller.
class AuthenticationController < ApplicationController
  before_filter :login_required, :except => :open
  def rescue_action(e) raise e end

  def restricted
    data = {:parent => {:child => "open"}}
    respond_to do |format|
      format.xml  { render :text => data.to_xml }
      format.json { render :text => data.to_json }
    end
  end

  def open
    data = {:parent => {:child => "restricted"}}
    respond_to do |format|
      format.xml  { render :text => data.to_xml }
      format.json { render :text => data.to_json }
    end
  end
end

class AuthenticationControllerTest < ActionController::TestCase

  context "Authenticated pages" do
    setup do
      @controller = AuthenticationController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.host = "www.example.com"
    end

    context "with configatron disable_api_authentication set to true" do
      setup do
        configatron.stubs(:disable_api_authentication).returns(true)
      end
      context "allow access to open HTML content" do
        setup do
          get :open
        end
        should_respond_with :success
      end
      context "allow access to open XML content" do
        setup do
          @request.accept = "application/xml"
          get :open
        end
        should_respond_with :success
        should_respond_with_content_type :xml
      end
      context "allow access to open JSON content" do
        setup do
          @request.accept = "application/json"
          get :open
        end
        should_respond_with :success
        should_respond_with_content_type :json
      end
      context "require login to restricted HTML content" do
        setup do
          get :restricted
        end
        should_respond_with :redirect
        should_redirect_to("login page") { login_path }
      end
      context "require login to restricted XML" do
        setup do
          @request.accept = "application/xml"
          get :restricted
        end
        should_respond_with :success
        should_respond_with_content_type :xml
      end
      context "require login to restricted JSON" do
        setup do
          @request.accept = "application/json"
          get :restricted
        end
        should_respond_with :success
        should_respond_with_content_type :json
      end
    end

    context "with configatron disable_api_authentication set to false" do
      setup do
        configatron.stubs(:disable_api_authentication).returns(false)
      end
      context "and HTML request" do
        context "will allow access to open content" do
          setup do
            get :open
          end
          should_respond_with :success
        end
        context "will require login to restricted content" do
          setup do
            get :restricted
          end
          should_respond_with :redirect
          should_redirect_to("login page") { login_path }
        end
        context "with valid api_key will not require login to restricted content" do
          setup do
            @user = Factory :user
            get :restricted, :api_key => @user.api_key
          end
          should_respond_with :success
        end
        context "with an invalid api_key will require login to restricted content" do
          setup do
            get :restricted, :api_key => "fakeapikey"
          end
          should_respond_with :redirect
          should_redirect_to("login page") { login_path }
        end
      end
      context "and XML request" do
        setup do
          @request.accept = "application/xml"
        end
        context "will allow access to open content" do
          setup do
            get :open
          end
          should_respond_with :success
          should_respond_with_content_type :xml
        end
        context "will require login to restricted content" do
          setup do
            get :restricted
          end
          should_respond_with :unauthorized
          should_respond_with_content_type :xml
        end
        context "with valid api_key will not require login to restricted content" do
          setup do
            @user = Factory :user
            get :restricted, :api_key => @user.api_key
          end
          should_respond_with :success
          should_respond_with_content_type :xml
        end
        context "with an invalid api_key will require login to restricted content" do
          setup do
            get :restricted, :api_key => "fakeapikey"
          end
          should_respond_with :unauthorized
          should_respond_with_content_type :xml
        end
      end
      context "and JSON request" do
        setup do
          @request.accept = "application/json"
        end
        context "will allow access to open content" do
          setup do
            get :open
          end
          should_respond_with :success
          should_respond_with_content_type :json
        end
        context "will require login to restricted content" do
          setup do
            get :restricted
          end
          should_respond_with :unauthorized
          should_respond_with_content_type :json
        end
        context "with valid api_key will not require login to restricted content" do
          setup do
            @user = Factory :user
            get :restricted, :api_key => @user.api_key
          end
          should_respond_with :success
          should_respond_with_content_type :json
        end
        context "with an invalid api_key will require login to restricted content" do
          setup do
            get :restricted, :api_key => "fakeapikey"
          end
          should_respond_with :unauthorized
          should_respond_with_content_type :json
        end
      end
    end
  end
end