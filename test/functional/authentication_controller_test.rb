# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

# Re-raise errors caught by the controller.
class AuthenticationController < ApplicationController
  before_action :login_required, except: :open

  def restricted
    data = { parent: { child: 'open' } }
    respond_to do |format|
      format.html { render text: '<html></html>' }
      format.xml  { render text: data.to_xml }
      format.json { render text: data.to_json }
    end
  end

  def open
    data = { parent: { child: 'restricted' } }
    respond_to do |format|
      format.html { render text: '<html></html>' }
      format.xml  { render text: data.to_xml }
      format.json { render text: data.to_json }
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
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.host = 'www.example.com'
      # skip_routing
    end

    context 'with configatron disable_api_authentication set to true' do
      setup do
        configatron.stubs(:disable_api_authentication).returns(true)
      end
      context 'allow access to open HTML content' do
        setup do
          get :open
        end
        should respond_with :success
      end
      context 'allow access to open XML content' do
        setup do
          @request.accept = 'application/xml'
          get :open
        end
        should respond_with :success
        should 'Respond with xml' do
          assert_equal 'application/xml', @response.content_type
        end
      end
      context 'allow access to open JSON content' do
        setup do
          @request.accept = 'application/json'
          get :open
        end
        should respond_with :success
        should 'Respond with json' do
         assert_equal 'application/json', @response.content_type
        end
      end
      context 'require login to restricted HTML content' do
        setup do
          get :restricted
        end
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
          assert_equal 'application/xml', @response.content_type
        end
      end
      context 'require login to restricted JSON' do
        setup do
          @request.accept = 'application/json'
          get :restricted
        end
        should respond_with :success
        should 'Respond with json' do
          assert_equal 'application/json', @response.content_type
        end
      end
    end

    context 'with configatron disable_api_authentication set to false' do
      setup do
        @memo = configatron.disable_api_authentication
        configatron.disable_api_authentication = false
      end
      teardown do
        configatron.disable_api_authentication = @memo
      end
      context 'and HTML request' do
        context 'will allow access to open content' do
          setup do
            get :open
          end
          should respond_with :success
        end
        context 'will require login to restricted content' do
          setup do
            get :restricted
          end
          should respond_with :redirect
          should redirect_to('login page') { login_path }
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryGirl.create :user
            get :restricted, api_key: @user.api_key
          end
          should respond_with :success
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup do
            get :restricted, api_key: 'fakeapikey'
          end
          should respond_with :redirect
          should redirect_to('login page') { login_path }
        end
      end
      context 'and XML request' do
        setup do
          @request.accept = 'application/xml'
        end
        context 'will allow access to open content' do
          setup do
            get :open
          end
          should respond_with :success
          should 'Respond with xml' do
            assert_equal 'application/xml', @response.content_type
          end
        end
        context 'will require login to restricted content' do
          setup do
            get :restricted
          end
          should respond_with :unauthorized
          should 'Respond with xml' do
            assert_equal 'application/xml', @response.content_type
          end
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryGirl.create :user
            get :restricted, api_key: @user.api_key
          end
          should respond_with :success
          should 'Respond with xml' do
            assert_equal 'application/xml', @response.content_type
          end
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup do
            get :restricted, api_key: 'fakeapikey'
          end
          should respond_with :unauthorized
          should 'Respond with xml' do
            assert_equal 'application/xml', @response.content_type
          end
        end
      end
      context 'and JSON request' do
        setup do
          @request.accept = 'application/json'
        end
        context 'will allow access to open content' do
          setup do
            get :open
          end
          should respond_with :success
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end
        end
        context 'will require login to restricted content' do
          setup do
            get :restricted
          end
          should respond_with :unauthorized
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end
        end
        context 'with valid api_key will not require login to restricted content' do
          setup do
            @user = FactoryGirl.create :user
            get :restricted, api_key: @user.api_key
          end
          should respond_with :success
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end
        end
        context 'with an invalid api_key will require login to restricted content' do
          setup do
            get :restricted, api_key: 'fakeapikey'
          end
          should respond_with :unauthorized
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end
        end
      end
    end
  end
end
