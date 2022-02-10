# frozen_string_literal: true

require 'test_helper'

module Studies
  class SamplesControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Studies::SamplesController.new
        @request = ActionController::TestRequest.create(@controller)

        @user = create :user
        session[:user] = @user.id
      end

      should_require_login(:index, resource: 'sample', parent: 'study')

      test_unit_class.resource_test(
        'sample',
        parent: 'study',
        actions: ['index'],
        ignore_actions: ['show'],
        formats: ['html']
      )
    end
  end
end
