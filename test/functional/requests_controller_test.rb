# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

require 'test_helper'
require 'requests_controller'

class RequestsControllerTest < ActionController::TestCase
  context 'Request controller' do
    setup do
      @controller = RequestsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :admin
    end

    should_require_login

    context '#cancel' do
      setup do
        session[:user] = @user.id
      end

      should 'cancel request' do
         request = FactoryGirl.create :request, user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon2'), workflow: FactoryGirl.create(:submission_workflow)
         get :cancel, id: request.id

         assert_equal flash[:notice], "Request #{request.id} has been cancelled"
         assert Request.find(request.id).cancelled?
         assert_response :redirect
      end

      should 'cancel started request' do
         request = FactoryGirl.create :request, state: 'started', user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon2'), workflow: FactoryGirl.create(:submission_workflow)
         get :cancel, id: request.id

         assert_equal flash[:error], "Request #{request.id} in progress. Can't be cancelled"
         assert_response :redirect
      end
    end

    context '#copy' do
      setup do
        session[:user] = @user.id
      end

      should 'when quotas is copied and redirect' do
        @request_initial = FactoryGirl.create :request, user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon2'), workflow: FactoryGirl.create(:submission_workflow)
         get :copy, id: @request_initial.id

         @new_request = Request.last
         assert_equal flash[:notice], "Created request #{@new_request.id}"
         assert_response :redirect
      end

      should 'set failed requests to pending' do
        @request_initial = FactoryGirl.create :request, user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon2'), workflow: FactoryGirl.create(:submission_workflow), state: 'failed'
         get :copy, id: @request_initial.id

         @new_request = Request.last
         assert_equal flash[:notice], "Created request #{@new_request.id}"
         assert_response :redirect

         assert_equal 'pending', @new_request.state
      end
    end

    context '#update' do
      setup do
        @prop_value_before = '999'
        @prop_value_after = 666

        @our_request = FactoryGirl.create :request, user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon'), workflow: FactoryGirl.create(:submission_workflow)
        @params = { request_metadata_attributes: { read_length: '37' }, state: 'pending', request_type_id: @our_request.request_type_id }
      end

      context 'when not logged in' do
        setup do
          put :update, id: @our_request.id, request: @params
        end
        should redirect_to('login page') { login_path }
      end

      context 'when logged in' do
        setup do
          @controller.stubs(:logged_in?).returns(@user)
          session[:user] = @user.id

          put :update, id: @our_request.id, request: @params
        end

        should redirect_to('request path') { request_path(@our_request) }

        should 'set the read length of the associated properties' do
          assert_equal 37, Request.find(@our_request.id).request_metadata.read_length
        end
      end
    end

    context '#update rejected' do
      setup do
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id

        @project = FactoryGirl.create(:project_with_order, name: 'Prj1')
         @reqwest = FactoryGirl.create :request, user: @user, request_type: FactoryGirl.create(:request_type), study: FactoryGirl.create(:study, name: 'ReqCon XXX'),
                                                 workflow: FactoryGirl.create(:submission_workflow), project: @project
      end

      context 'update invalid and failed' do
        setup do
          @params = { request_metadata_attributes: { read_length: '37' }, state: 'invalid' }
          put :update, id: @reqwest.id, request: @params
        end
        should redirect_to('request path') { request_path(@reqwest) }
      end

      context "update to state 'failed'" do
        setup do
          @prop_value_after = 666
          @params = { request_metadata_attributes: { read_length: '37' }, state: 'failed' }
          put :update, id: @reqwest.id, request: @params
        end
        should 'not update the state' do
          # We really don't want arbitrary changing of state
          assert @reqwest.state != 'failed'
        end
      end
    end
  end
end
