# frozen_string_literal: true

require 'test_helper'

class RequestsControllerTest < ActionController::TestCase
  context 'Request controller' do
    setup do
      @controller = RequestsController.new
      @request = ActionController::TestRequest.create(@controller)
      @user = FactoryBot.create(:admin)
    end

    should_require_login

    context '#cancel' do
      setup { session[:user] = @user.id }

      should 'cancel request' do
        request =
          FactoryBot.create(
            :request,
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon2')
          )
        get :cancel, params: { id: request.id }

        assert_equal flash[:notice], "Request #{request.id} has been cancelled"
        assert Request.find(request.id).cancelled?
        assert_response :redirect
      end

      should 'cancel started request' do
        request =
          FactoryBot.create(
            :request,
            state: 'started',
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon2')
          )
        get :cancel, params: { id: request.id }

        assert_equal flash[:error], "Request #{request.id} can't be cancelled"
        assert_response :redirect
      end
    end

    context '#copy' do
      setup { session[:user] = @user.id }

      should 'when quotas is copied and redirect' do
        @request_initial =
          FactoryBot.create(
            :request,
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon2')
          )
        get :copy, params: { id: @request_initial.id }

        @new_request = Request.last
        assert_equal flash[:notice], "Created request #{@new_request.id}"
        assert_response :redirect
      end

      should 'set failed requests to pending' do
        @request_initial =
          FactoryBot.create(
            :request,
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon2'),
            state: 'failed'
          )
        get :copy, params: { id: @request_initial.id }

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

        @our_request =
          FactoryBot.create(
            :request,
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon')
          )
        @params = {
          request_metadata_attributes: {
            read_length: '37'
          },
          state: 'pending',
          request_type_id: @our_request.request_type_id
        }
      end

      context 'when not logged in' do
        setup { put :update, params: { id: @our_request.id, request: @params } }
        should redirect_to('login page') { login_path }
      end

      context 'when logged in' do
        setup do
          @controller.stubs(:logged_in?).returns(@user)
          session[:user] = @user.id

          put :update, params: { id: @our_request.id, request: @params }
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

        @project = FactoryBot.create(:project_with_order, name: 'Prj1')
        @reqwest =
          FactoryBot.create(
            :request,
            user: @user,
            request_type: FactoryBot.create(:request_type),
            study: FactoryBot.create(:study, name: 'ReqCon XXX'),
            project: @project
          )
      end

      context 'update invalid and failed' do
        setup do
          @params = { request_metadata_attributes: { read_length: '37' }, state: 'invalid' }
          put :update, params: { id: @reqwest.id, request: @params }
        end
        should redirect_to('request path') { request_path(@reqwest) }
      end

      context "update to state 'failed'" do
        setup do
          @prop_value_after = 666
          @params = { request_metadata_attributes: { read_length: '37' }, state: 'failed' }
          put :update, params: { id: @reqwest.id, request: @params }
        end
        should 'not update the state' do
          # We really don't want arbitrary changing of state
          assert @reqwest.state != 'failed'
        end
      end
    end
  end
end
