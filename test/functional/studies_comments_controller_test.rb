require "test_helper"

# Re-raise errors caught by the controller.
class Studies::CommentsController; def rescue_action(e) raise e end; end

class Studies::CommentsControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::CommentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test('comment', {:actions => ['index'], :ignore_actions => ["new", "edit", "update", "show", 'destroy', 'create'], :formats => ['html'], :parent => "study", :other_actions => ['add']})

  end
end
