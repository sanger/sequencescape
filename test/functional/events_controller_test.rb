require "test_helper"
require 'events_controller'

# Re-raise errors caught by the controller.
class EventsController; def rescue_action(e) raise e end; end

class EventsControllerTest < ActionController::TestCase
  context "EventsController" do
    setup do
      @controller = EventsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @event = Event.create
    end

    should_require_login :new, :create

    context "#create" do
      context "HTML" do
        setup do
          @controller.stubs(:login_required).returns(true)
          put :create, :event => {:key => 'blah'}
        end
        should_respond_with :success
      end
      context "XML" do
        setup do
          get :create, :format => :xml
        end
        should_respond_with :not_acceptable
      end
    end
  end
end
