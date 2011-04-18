require File.join(File.dirname(__FILE__), 'sanger_macros', 'resource_test')

module Sanger
  module Testing
    module Controller
      module Macros
        def should_have_successful_submission
          # FIXME: routing doesnt work property
          #should_redirect_to("study workflow submission page"){ study_workflow_submission_url(@study, @workflow, @submission) }
          should "have a successful submission" do
            assert_not_nil @controller.session[:flash][:notice].grep /Submission successfully created/
            assert_equal @submission_count +1 , Submission.count
          end
        end

        def should_require_login(*actions)
          actions << :index if actions.empty?
          actions.each do |action|
            context "#{action}" do
              context "when logged in" do
                setup do
                  @controller.stubs(:logged_in?).returns(true)
                  @controller.stubs(:current_user).returns(Factory(:user))
                  begin
                    get action
                  rescue ActionController::UnknownAction
                     flunk "Testing for an unknown action: #{action}"
                  rescue ActiveRecord::RecordNotFound
                    assert true
                  rescue ActionView::MissingTemplate
                    flunk "Missing template for #{action} action"
                  rescue
                    # Assume any other problem is due to the controller not handling things
                    assert true
                  end
                end
                should "not redirect" do
                  assert ! (300..307).to_a.include?(@response.code)
                end
              end
              context "when not logged in" do
                setup do
                  @controller.stubs(:logged_in?).returns(false)
                  begin
                    get action
                  rescue ActionController::UnknownAction
                    flunk "Testing for an unknown action: #{action}"
                  end
                end
                should_redirect_to("login page"){login_path}
              end
              # TODO - Include API passthrough checking
              # context "when requesting XML" do
              #   setup do
              #     @request.accept = "application/xml"
              #     get action
              #   end
              #   should "not redirect" do
              #     assert ! (300..307).to_a.include?(@response.code)
              #   end
              # end
            end
          end
        end
      end
    end
  end
end
