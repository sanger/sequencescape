# frozen_string_literal: true

require 'test_helper'

module Samples
  class CommentsControllerTest < ActionController::TestCase
    context 'Samples#Comments controller' do
      setup do
        @controller = Samples::CommentsController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login(:index, resource: 'comment', parent: 'sample')

      test_unit_class.resource_test(
        'comment',
        actions: ['index'],
        ignore_actions: %w[destroy create edit new show update],
        formats: ['html'],
        parent: 'sample'
      )
    end
  end
end
