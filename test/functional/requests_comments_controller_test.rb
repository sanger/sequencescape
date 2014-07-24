require "test_helper"

# Re-raise errors caught by the controller.
class Requests::CommentsController; def rescue_action(e) raise e end; end

class Requests::CommentsControllerTest < ActionController::TestCase
  context "Requests controller" do
    setup do
      @controller = Requests::CommentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test('comment', {:actions => ['index'], :ignore_actions => ["new", "edit", "update", "show", 'destroy', 'create'], :formats => ['html'], :parent => "request"})

  end
end
