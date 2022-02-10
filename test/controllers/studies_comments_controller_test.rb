# frozen_string_literal: true

require 'test_helper'

module Studies
  class CommentsControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Studies::CommentsController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login(:index, resource: 'comment', parent: 'study')

      test_unit_class.resource_test(
        'comment',
        actions: ['index'],
        ignore_actions: %w[new edit update show destroy create],
        formats: ['html'],
        parent: 'study',
        other_actions: ['add']
      )
    end
  end
end
