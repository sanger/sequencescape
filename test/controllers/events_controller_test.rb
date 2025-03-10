# frozen_string_literal: true

require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  context 'EventsController' do
    setup do
      @controller = EventsController.new
      @request = ActionController::TestRequest.create(@controller)
      @event = Event.create
    end

    should_require_login :new, :create

    context '#create' do
      context 'HTML' do
        # This test has been imported from the rails 2 days.
        # Oddly we still seemed to return XML content so
        # I have no idea what was going  on here. Give the
        # test below, it was probably just a mistake.
        setup do
          @controller.stubs(:login_required).returns(true)
          put :create, params: { event: { key: 'blah' } }
        end
        should respond_with :success
      end

      # Prior to the rails 3 upgrade, the xml test actually expected
      # a not_acceptable response. This seemed weird, and only passed
      # as the rails2 tests don't handle formats provided as symbols
      # correctly. This tests we preserve the actual behaviour, which
      # also feels like the RIGHT behaviour.
      context 'XML' do
        setup { get :create, params: { format: :xml, event: { key: 'blah' } } }
        should respond_with :success
      end
    end
  end
end
