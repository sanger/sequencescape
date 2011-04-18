require "test_helper"

# Re-raise errors caught by the controller.
class Studies::EventsController; def rescue_action(e) raise e end; end

class Studies::EventsControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::EventsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @user     = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @study  = Factory :study
    end

    should_require_login(:index)

     context "#index" do
        setup do
          @controller.stubs(:current_user).returns(Factory(:user))
          get :index, :study_id => @study.id
        end
        should_respond_with :success
        should_render_template :index
      end
  end
end
