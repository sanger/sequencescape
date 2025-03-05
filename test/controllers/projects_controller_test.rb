# frozen_string_literal: true

require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  context 'ProjectsController' do
    setup do
      @controller = ProjectsController.new
      @request = ActionController::TestRequest.create(@controller)
    end

    should_require_login
  end

  context 'create a project - custom' do
    setup do
      @controller = ProjectsController.new
      @request = ActionController::TestRequest.create(@controller)
      @user = FactoryBot.create(:user)
      session[:user] = @user.id
    end

    context '#new' do
      setup { get :new }

      should respond_with :success
      should render_template :new
    end

    context '#create' do
      setup { @request_type_1 = FactoryBot.create(:request_type) }

      context 'successfully create a new project' do
        setup do
          @project_counter = Project.count
          post :create,
               params: {
                 'project' => {
                   'name' => 'hello',
                   :project_metadata_attributes => {
                     project_cost_code: 'Some cost code',
                     project_funding_model: 'Internal'
                   }
                 }
               }
        end

        should set_flash.to('Your project has been created')
        should redirect_to('last project page') { project_path(Project.last) }
        should 'change Project.count by 1' do
          assert_equal 1, Project.count - @project_counter
        end
      end

      context 'with invalid data' do
        setup do
          @initial_project_count = Project.count
          post :create,
               params: {
                 'project' => {
                   'name' => 'hello 2',
                   :project_metadata_attributes => {
                     project_cost_code: '',
                     project_funding_model: ''
                   }
                 }
               }
        end

        should render_template :new
        should 'not change Project.count' do
          assert_equal @initial_project_count, Project.count
        end

        should set_flash.now.to('Problems creating your new project')
      end

      context 'create a new project using permission allowed (not required)' do
        setup do
          @project_counter = Project.count
          post :create,
               params: {
                 'project' => {
                   'name' => 'hello 3',
                   :project_metadata_attributes => {
                     project_cost_code: 'Some cost code',
                     project_funding_model: 'Internal'
                   }
                 }
               }
        end

        should redirect_to('last project added page') { project_path(Project.last) }
        should set_flash.to('Your project has been created')
        should 'change Project.count by 1' do
          assert_equal 1, Project.count - @project_counter
        end
      end
    end
  end

  context "POST '/create'" do
    context 'with JSON data' do
      setup do
        @user = FactoryBot.create(:user, api_key: 'abc')
        session[:user] = @user.id

        @json_data = <<-END_OF_JSON_DATA
          {
            "api_version": "#{RELEASE.api_version}",
            "api_key": "abc",
            "project": {
              "name": "Some Project",
              "project_metadata_attributes": {
                "project_cost_code": "Some cost code",
                "project_funding_model": "Internal"
              }
            }
          }
        END_OF_JSON_DATA

        @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
        post :create, params: ActiveSupport::JSON.decode(@json_data)
      end

      should set_flash.to('Your project has been created')
    end
  end
end
