# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'events_controller'

class EventsControllerTest < ActionController::TestCase
  context 'EventsController' do
    setup do
      @controller = EventsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
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
          put :create, event: { key: 'blah' }
        end
        should respond_with :success
      end

      # Prior to the rails 3 upgrade, the xml test actually expected
      # a not_acceptable response. This seemed weird, and only passed
      # as the rails2 tests don't handle formats provided as symbols
      # correctly. This tests we preserve the actual behaviour, which
      # also feels like the RIGHT behaviour.
      context 'XML' do
        setup do
          get :create, format: :xml, event: { key: 'blah' }
        end
        should respond_with :success
      end
    end
  end
end
