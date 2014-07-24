require "test_helper"
require 'tasks_controller'

class TasksControllerTest < ActionController::TestCase

  context "TasksController" do
    setup do
      @controller = TasksController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = Factory :admin
      @controller.stubs(:current_user).returns(@user)
      @pipeline = Factory :pipeline, :name => "Normal pipeline"
      @workflow = @pipeline.workflow
      @task = Factory :task, :workflow => @workflow, :name => "A new task name"
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end

      should_render_template :index
    end

    context "#show" do
      setup do
        get :show, :id => @task.id
      end

      should_render_template :show
    end

    context "#new" do
      setup do
        get :new, {:workflow_id => @workflow.id}
      end

      should "render new" do
        assert_response :success
      end
    end

    context "#create_task" do
      setup do
        @old_count = Task.count
        post  :create,
              :descriptor => {"1" => {"name" => "Yeah", "kind" => "Text", "selection" => {"1" => ""}}},
              :task => {"name" => "A Task", "pipeline_workflow_id" => "1", "sorted" => "1", "batched" => "1"}
      end

      should "render create_task" do
        assert_equal @old_count+1, Task.count
        assert_redirected_to task_path(assigns(:task))
      end
    end

    context "#edit" do
      setup do
        get :edit, :id => @task.id
      end

      should "render edit" do
        assert_response :success
      end
    end

    context "#update_task" do
      setup do
        put :update,
            :id => @task.id,
            :descriptor => {"1" => {"name" => "Yeah", "kind" => "Text", "selection" => {"1" => ""}}},
            :task => {"name" => "A Task", "pipeline_workflow_id" => "1", "sorted" => "1", "batched" => "1"}
      end

      should "render update task" do
        assert_redirected_to task_path(assigns(:task))
      end
    end

    context "#destroy_task" do
      setup do
        @old_count = Task.count
        delete :destroy, :id => @task.id
      end

      should "destroy given tasks" do
        assert_equal @old_count-1, Task.count
        assert_redirected_to tasks_path
      end
    end
  end

end
