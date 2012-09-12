require "test_helper"

# Re-raise errors caught by the controller.
class Projects::Workflows::QuotasController; def rescue_action(e) raise e end; end

class Projects::Workflows::QuotasControllerTest < ActionController::TestCase
  context "Quotas controller" do
    setup do
      @controller = Projects::Workflows::QuotasController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @workflow   = Factory :submission_workflow
      @quota      = Factory :project_quota

      Factory(:admin, :email => 'admin1@example.com')

      user = Factory(:user, :workflow => @workflow)
      @controller.stubs(:current_user).returns(user)
      @controller.stubs(:logged_in?).returns(user) # Was Factory(:user)
    end

    should_require_login

    context "#update_request" do
      setup do
        get :update_request, :project_id => @quota.project.id, :workflow_id => @workflow.id
      end
      should_respond_with :success
      should_render_template :update_request
    end

    context "#send_request" do
      setup do
        get :send_request, :project_id => @quota.project.id, :workflow_id => @workflow.id, :limits => {@quota.request_type.key => 10}, :comment => "Want more quota"
      end

      should 'have a subject which include "Project"' do
        assert_sent_email { |email| email.subject =~ /Project/ }
      end

      should 'have sent an email to admin1@example.com' do
        assert_sent_email { |email| email.bcc.include?('admin1@example.com') }
      end

      should 'have a body which includes the quota change' do
        assert_sent_email { |email| email.body =~ /An increase in #{@quota.request_type.name.downcase} quota: from 0 to 10/ }
      end

      should_redirect_to("project_path(@quota.project)"){ project_path(@quota.project) }
    end

  end
end
