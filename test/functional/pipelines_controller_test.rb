# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'pipelines_controller'

class PipelinesControllerTest < ActionController::TestCase
  context 'Pipelines controller' do
    setup do
      @controller = PipelinesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :user
      session[:user] = @user.id
    end
    should_require_login

    context '#index' do
      setup do
        get :index
      end

      should respond_with :success
    end

    context '#batches' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
      end
      context 'without any pipeline batches' do
        setup do
          get :batches, id: @pipeline.id.to_s
        end

        should respond_with :success
      end

      context 'with 1 batch' do
        setup do
         FactoryGirl.create :batch, pipeline: @pipeline
          get :batches, id: @pipeline.id.to_s
        end

        should respond_with :success
      end
    end

    context '#show' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
        get :show, id: @pipeline
      end

      should respond_with :success
      context 'and no batches' do
        setup do
          @pipeline = FactoryGirl.create :pipeline
          get :show, id: @pipeline
        end

        should respond_with :success
      end
    end

    context '#setup_inbox' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
        get :setup_inbox, id: @pipeline.id.to_s
      end

      should respond_with :success
    end

    context '#training_batch' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
        get :training_batch, id: @pipeline.id.to_s
      end

      should respond_with :success
    end

    context '#activate' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
        get :activate, id: @pipeline.id.to_s
      end

      should respond_with :redirect
    end

    context '#deactivate' do
      setup do
        @pipeline = FactoryGirl.create :pipeline
        get :deactivate, id: @pipeline.id.to_s
      end

      should respond_with :redirect
    end
  end
end
