# frozen_string_literal: true

require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  context 'Admin controller' do
    setup do
      @controller = AdminController.new
      @request = ActionController::TestRequest.create(@controller)
    end

    should_require_login

    context 'admin frontpage' do
      setup { session[:user] = @user = create(:admin) }

      context '#index' do
        setup { get :index }
        should respond_with :success
        should render_template :index
      end

      context '#filter' do
        setup { get :filter }
        should respond_with :success
        should render_template 'admin/users/_users'
      end

      context '#filter with query' do
        setup { get :filter, params: { q: 'abc123' } }
        should respond_with :success
        should render_template 'admin/users/_users'
      end
    end
  end
end
