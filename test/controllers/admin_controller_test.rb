# frozen_string_literal: true

require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  context 'Admin controller' do
    setup do
      @controller = AdminController.new
      @request    = ActionController::TestRequest.create(@controller)
    end

    should_require_login

    context 'admin frontpage' do
      setup do
        session[:user] = @user = create :admin
      end

      context '#index' do
        setup do
          get :index
        end
        should respond_with :success
        should render_template :index
      end

      context '#filter' do
        setup do
          get :filter
        end
        should respond_with :success
        should render_template 'admin/users/_users'
      end

      context '#filter with query' do
        setup do
          get :filter, params: { q: 'abc123' }
        end
        should respond_with :success
        should render_template 'admin/users/_users'
      end
    end
  end
end
