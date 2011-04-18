require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class Admin::StudiesController; def rescue_action(e) raise e end; end

class Admin::StudiesControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Admin::StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context "management UI" do
      setup do
        @user     = Factory :admin
        @study  = Factory :study
        @request_type = Factory :request_type
        @controller.stubs(:current_user).returns(@user)
        @controller.stubs(:logged_in?).returns(@user)
        @emails = ActionMailer::Base.deliveries
        @emails.clear
      end

      context "#managed_update (without changes)" do
        setup do
          get :managed_update, :id => @study.id, :study => { :name => @study.name, :reference_genome_id => @study.reference_genome_id }
        end

        should "not send an email" do
          assert_equal [], @emails
        end

        should_redirect_to("admin studies path") { "/admin/studies/#{@study.id}" }
      end

    end

  end
end
