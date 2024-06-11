# frozen_string_literal: true

require 'test_helper'

module Studies
  class EventsControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Studies::EventsController.new
        @request = ActionController::TestRequest.create(@controller)

        @user = create(:user)
        session[:user] = @user.id
        @study = create(:study)
      end

      should_require_login(:index, resource: 'event', parent: 'study')

      context '#index' do
        setup { get :index, params: { study_id: @study.id } }
        should respond_with :success
        should render_template :index
      end
    end
  end
end
