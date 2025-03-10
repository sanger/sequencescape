# frozen_string_literal: true

require 'test_helper'

class StudiesControllerTest < ActionController::TestCase
  context 'StudiesController' do
    setup do
      @controller = StudiesController.new
      @request = ActionController::TestRequest.create(@controller)
    end

    resource_test(
      'study',
      defaults: {
        name: 'study name'
      },
      user: :admin,
      other_actions: %w[properties study_status],
      ignore_actions: %w[show create update destroy],
      formats: ['xml']
    )
  end
end
