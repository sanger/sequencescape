require "test_helper"
require 'home_controller'

class HomeControllerTest < ActionController::TestCase
  context "#Home controller" do
    setup do
      @controller = HomeController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end
    
    should "#index" do
      get :index
      assert_redirected_to :controller => "sessions", :action => "login"
    end
  end
end