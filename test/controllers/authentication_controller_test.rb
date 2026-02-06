# frozen_string_literal: true

require 'test_helper'

# Re-raise errors caught by the controller.
class AuthenticationController < ApplicationController
  before_action :login_required, except: :open

  def restricted
    data = { parent: { child: 'open' } }
    respond_to do |format|
      format.html { render plain: '<html></html>' }
      format.xml { render plain: data.to_xml }
      format.json { render plain: data.to_json }
    end
  end

  def open
    data = { parent: { child: 'restricted' } }
    respond_to do |format|
      format.html { render plain: '<html></html>' }
      format.xml { render plain: data.to_xml }
      format.json { render plain: data.to_json }
    end
  end
end

class AuthenticationControllerTest < ActionController::TestCase
  # def skip_routing
  #   Rails.application.routes.draw do
  #     get 'authentication/open'
  #     get 'authentication/restricted'
  #     match '/login' => 'sessions#login', :as => :login, :via => [:get,:post]
  #     match '/logout' => 'sessions#logout', :as => :logout, :via => [:get,:post]
  #   end
  # end

  context 'Authenticated pages' do
    setup do
      @controller = AuthenticationController.new
      @request = ActionController::TestRequest.create(@controller)
      @request.host = 'www.example.com'
      # skip_routing
    end

    context 'with configatron disable_api_authentication set to true' do
      setup { configatron.stubs(:disable_api_authentication).returns(true) }
      context 'allow access to open HTML content' do
        setup { get :open }
        should respond_with :success
      end
      context 'allow access to open XML content' do
        setup do
          @request.accept = 'application/xml'
          get :open
        end
        should respond_with :success

        should 'Respond with xml' do
          assert_equal 'application/xml', @response.media_type
        end
      end
      context 'allow access to open JSON content' do
        setup do
          @request.accept = 'application/json'
          get :open
        end
        should respond_with :success

        should 'Respond with json' do
          assert_equal 'application/json', @response.media_type
        end
      end
      context 'require login to restricted HTML content' do
        setup { get :restricted }
        should respond_with :redirect
        should redirect_to('login page') { login_path }
      end
      context 'require login to restricted XML' do
        setup do
          @request.accept = 'application/xml'
          get :restricted
        end
        should respond_with :success

        should 'Respond with xml' do
          assert_equal 'application/xml', @response.media_type
        end
      end
      context 'require login to restricted JSON' do
        setup do
          @request.accept = 'application/json'
          get :restricted
        end
        should respond_with :success

        should 'Respond with json' do
          assert_equal 'application/json', @response.media_type
        end
      end
    end

    context 'with configatron disable_api_authentication set to false' do
      setup do
        @memo = configatron.disable_api_authentication
        configatron.disable_api_authentication = false
      end
      teardown { configatron.disable_api_authentication = @memo }
      context 'and HTML request' do
        context 'will allow access to open content' do
          setup { get :open }
          should respond_with :success
        end
        context 'will require login to restricted content' do
          setup { get :restricted }
          should respond_with :redirect
          should redirect_to('login page') { login_path }
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryBot.create(:user)
            get :restricted, params: { api_key: @user.api_key }
          end
          should respond_with :success
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup { get :restricted, params: { api_key: 'fakeapikey' } }
          should respond_with :redirect
          should redirect_to('login page') { login_path }
        end
      end
      context 'and XML request' do
        setup { @request.accept = 'application/xml' }
        context 'will allow access to open content' do
          setup { get :open }
          should respond_with :success

          should 'Respond with xml' do
            assert_equal 'application/xml', @response.media_type
          end
        end
        context 'will require login to restricted content' do
          setup { get :restricted }
          should respond_with :unauthorized

          should 'Respond with xml' do
            assert_equal 'application/xml', @response.media_type
          end
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryBot.create(:user)
            get :restricted, params: { api_key: @user.api_key }
          end
          should respond_with :success

          should 'Respond with xml' do
            assert_equal 'application/xml', @response.media_type
          end
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup { get :restricted, params: { api_key: 'fakeapikey' } }
          should respond_with :unauthorized

          should 'Respond with xml' do
            assert_equal 'application/xml', @response.media_type
          end
        end
      end
      context 'and JSON request' do
        setup { @request.accept = 'application/json' }
        context 'will allow access to open content' do
          setup { get :open }
          should respond_with :success

          should 'Respond with json' do
            assert_equal 'application/json', @response.media_type
          end
        end
        context 'will require login to restricted content' do
          setup { get :restricted }
          should respond_with :unauthorized

          should 'Respond with json' do
            assert_equal 'application/json', @response.media_type
          end
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryBot.create(:user)
            get :restricted, params: { api_key: @user.api_key }
          end
          should respond_with :success

          should 'Respond with json' do
            assert_equal 'application/json', @response.media_type
          end
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup { get :restricted, params: { api_key: 'fakeapikey' } }
          should respond_with :unauthorized

          should 'Respond with json' do
            assert_equal 'application/json', @response.media_type
          end
        end
      end
    end
  end
end
