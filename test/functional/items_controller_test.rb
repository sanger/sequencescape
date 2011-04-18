require "test_helper"

class ItemsControllerTest < ActionController::TestCase
  setup do
      @controller = ItemsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
  end
  should_require_login
  
#  resource_test('item', {:user => :admin,:defaults => {:study_id  => "23"}, :formats => ['html']})
end
