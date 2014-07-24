require "test_helper"


class Samples::CommentsControllerTest < ActionController::TestCase
  context "Samples#Comments controller" do
    setup do
      @controller = Samples::CommentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test('comment', {:actions => ['index'], :ignore_actions => ['destroy', 'create', 'edit', 'new','show','update'], :formats => ['html'], :parent => "sample"})

  end
end
