require "test_helper"

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < ActionController::TestCase
  context "Admin controller" do
    setup do
      @controller = AdminController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login
    context "admin frontpage" do
      setup do
        @user     = Factory :admin
        @controller.stubs(:current_user).returns(@user)
        @controller.stubs(:logged_in?).returns(@user)
      end
      context "#index" do
        setup do
          get :index
        end
        should_respond_with :success
        should_render_template :index
      end

      context "#filter" do
        setup do
          get :filter
        end
        should_respond_with :success
        should_render_template "admin/users/_users"
      end

      context "#filter with query" do
        setup do
          get :filter, :q => "abc123"
        end
        should_respond_with :success
        should_render_template "admin/users/_users"
      end

    end
  end
end
