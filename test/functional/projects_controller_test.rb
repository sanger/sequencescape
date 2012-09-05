require "test_helper"
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < ActionController::TestCase
  context "ProjectsController" do
    setup do
      @controller = ProjectsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login
  end

  context "create a project - custom" do
    setup do
      @controller = ProjectsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user
      @user.has_role('owner')
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)
    end

    context "#new" do
      setup do
        get :new
      end

      should_respond_with :success
      should_render_template :new


    end

    context "#create" do
      setup do
        @request_type_1 = Factory :request_type
      end

      context "successfully create a new project" do
        setup do
          @project_counter  = Project.count
          post :create, "project" => {
            "name" => "hello",
            :project_metadata_attributes => {
              :project_cost_code => 'Some cost code'
            },
            :quotas => {"#{@request_type_1.id}"=>"0"}
          }
        end

        should_set_the_flash_to "Your project has been created"
        should_redirect_to("last project page") { project_path(Project.last) }
        should_change('Project.count', 1) { Project.count }
      end

      context "with invalid data" do
        setup do
          post :create, "project" => {
            "name" => "hello 2",
            :project_metadata_attributes => {
              :project_cost_code => ''
            },
            "quotas" => {"#{@request_type_1.id}"=>"0"}
          }
        end

        should_render_template :new
        should_not_change('Project.count') { Project.count }

        should 'set a message for the error' do
          assert_contains(@controller.action_flash.values, 'Problems creating your new project')
        end
      end

      context "create a new project using permission allowed (not required)" do
        setup do
          post :create, "project" => {
            "name" => "hello 3",
            :project_metadata_attributes => {
              :project_cost_code => 'Some cost code'
            },
            :quotas => {"#{@request_type_1.id}"=>"0"}
          }
        end

        should_redirect_to("last project added page") { project_path(Project.last) }
        should_set_the_flash_to "Your project has been created"
        should_change('Project.count', 1) { Project.count }
      end

    end
  end

  context "POST '/create'" do
    context "with JSON data" do
      setup do
        @user = Factory :user
        @user.has_role('owner')
        @controller.stubs(:logged_in?).returns(@user)
        @controller.stubs(:current_user).returns(@user)

        @json_data = <<-END_OF_JSON_DATA
          {
            "api_version": "#{RELEASE.api_version}",
            "api_key": "abc",
            "project": {
              "name": "Some Project",
              "project_metadata_attributes": {
                "project_cost_code": "Some cost code"
              }
            }
          }
        END_OF_JSON_DATA

        @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
        post :create, ActiveSupport::JSON.decode(@json_data)
      end

      should_set_the_flash_to "Your project has been created"
    end
  end
end
