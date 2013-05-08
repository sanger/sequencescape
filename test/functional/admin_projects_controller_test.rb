require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class Admin::ProjectsController; def rescue_action(e) raise e end; end

class Admin::ProjectsControllerTest < ActionController::TestCase
  context "Projects controller" do
    setup do
      @controller = Admin::ProjectsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context "management UI" do
      setup do
        @user     = Factory :admin
        @project  = Factory :project, :approved => false
        role = Factory :owner_role, :authorizable => @project
        role.users << @user
        @request_type = Factory :request_type
        @other_request_type = Factory :request_type
        @controller.stubs(:current_user).returns(@user)
        @controller.stubs(:logged_in?).returns(@user)
        @emails = ActionMailer::Base.deliveries
        @emails.clear
      end

      context "#managed_update (without changes)" do
        setup do
          get :managed_update, :id => @project.id, :project => { :name => @project.name }
        end

        should "not send an email" do
          assert_equal [], @emails
        end

        should_redirect_to("admin projects") { "/admin/projects/#{@project.id}" }
      end


      context "#managed_update (with getting approved)" do
        setup do
          get :managed_update, :id => @project.id, :project => { :approved => true, :name => @project.name }
        end

        should_redirect_to("admin project") { "/admin/projects/#{@project.id}" }
        should_set_the_flash_to "Your project has been updated"

        should_change("Event.count", :by => 1) { Event.count }

        should "send an email" do
          assert_sent_email do |email|
            email.subject   =~ /Project/ && email.subject =~ /[TEST]/ && email.bcc.include?(@project.owner.email)
            email.bcc.size  == 2
            email.body      =~ /Project approved by/
          end
        end
      end
    end


  end
end
