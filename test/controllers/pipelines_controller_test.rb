# frozen_string_literal: true

require 'test_helper'

class PipelinesControllerTest < ActionController::TestCase
  context 'Pipelines controller' do
    setup do
      @controller = PipelinesController.new
      @request = ActionController::TestRequest.create(@controller)
      @user = FactoryBot.create(:user)
      session[:user] = @user.id
    end
    should_require_login

    context '#index' do
      setup { get :index }

      should respond_with :success
    end

    context '#batches' do
      setup { @pipeline = FactoryBot.create(:pipeline) }
      context 'without any pipeline batches' do
        setup { get :batches, params: { id: @pipeline.id.to_s } }

        should respond_with :success
      end

      context 'with 1 batch' do
        setup do
          FactoryBot.create(:batch, pipeline: @pipeline)
          get :batches, params: { id: @pipeline.id.to_s }
        end

        should respond_with :success
      end
    end

    context '#show' do
      setup do
        @pipeline = FactoryBot.create(:pipeline)
        get :show, params: { id: @pipeline }
      end

      should respond_with :success
      context 'and no batches' do
        setup do
          @pipeline = FactoryBot.create(:pipeline)
          get :show, params: { id: @pipeline }
        end

        should respond_with :success
      end
    end

    context '#activate' do
      setup do
        @pipeline = FactoryBot.create(:pipeline)
        get :activate, params: { id: @pipeline.id.to_s }
      end

      should respond_with :redirect
    end

    context '#deactivate' do
      setup do
        @pipeline = FactoryBot.create(:pipeline)
        get :deactivate, params: { id: @pipeline.id.to_s }
      end

      should respond_with :redirect
    end
  end
end
