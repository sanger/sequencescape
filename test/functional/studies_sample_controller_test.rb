require "test_helper"
require 'studies/workflows_controller'

# Re-raise errors caught by the controller.
class Studies::SamplesController; def rescue_action(e) raise e end; end

class Studies::SamplesControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::SamplesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @user     = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @workflow = Factory :submission_workflow
    end

    should_require_login(:index)

    resource_test('sample',{:parent => 'study', :actions => ['index'], :ignore_actions =>['show'], :formats => ['html']})

  end
end
