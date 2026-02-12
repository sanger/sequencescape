# frozen_string_literal: true

require 'test_helper'

module Requests
  class CommentsControllerTest < ActionController::TestCase
    context 'Requests controller' do
      setup do
        @controller = Requests::CommentsController.new
        @request = ActionController::TestRequest.create(@controller)
        @user = create(:user)
        session[:user] = @user.id
      end

      should_require_login(:index, resource: 'comment', parent: 'request')

      resource_test(
        'comment',
        actions: ['index'],
        ignore_actions: %w[new edit update show destroy create],
        formats: ['html'],
        parent: 'request'
      )

      context 'with an ajax request' do
        setup do
          @rq = create(:request)

          %w[this is a test].each { |description| create(:comment, description: description, commentable: @rq) }
        end

        should 'return a ul of comments' do
          get :index, params: { request_id: @rq.id }, xhr: true

          assert_template partial: '_simple_list'
        end
      end
    end
  end
end
