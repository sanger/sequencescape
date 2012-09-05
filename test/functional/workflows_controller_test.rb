require File.join(File.dirname(__FILE__), %w[.. test_helper])
require 'workflows_controller'

ActionController::TestCase.send(:include, AuthenticatedTestHelper)

class WorkflowsControllerTest < ActionController::TestCase

  context "WorkflowController" do
    setup do
      @controller = WorkflowsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @pipeline_user = Factory :pipeline_admin, :login => @user.login

    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end

      should_respond_with :success
    end

    context "#new" do
      setup do
        get :new
      end

      should "#render new" do
        assert_response :success
      end
    end

    context "#create_workflow" do
      setup do
        @old_count = LabInterface::Workflow.count
        post :create, :workflow => { :name => "Workflow 42", :item_limit => 1, :locale => "Internal" },"commit"=>"Create"
      end

      should "#create_workflow" do
        assert_equal @old_count+1, LabInterface::Workflow.count
        assert_redirected_to workflow_path(assigns(:workflow))
      end

      context "actions on exsiting records" do
        setup do
          @wk = Factory(:pipeline, :name => 'New workflow').workflow
        end

        context "#show_workflow" do
          setup do
            get :show, :id => LabInterface::Workflow.first.id
          end

          should "show workflow" do
            assert_response :success
          end
        end

        context "edit" do
          setup do
            get :edit, :id => LabInterface::Workflow.first.id
          end

          should "render edit" do
            assert_response :success
          end
        end

        context "#update_workflow" do
          setup do
            put :update, :id => LabInterface::Workflow.first.id, :workflow => { }
          end

          should "update the workflow" do
            assert_redirected_to workflow_path(assigns(:workflow))
          end
        end

        context "#destroy_workflow" do
          setup do
            @old_count = LabInterface::Workflow.count
            delete :destroy, :id => LabInterface::Workflow.first.id
          end

          should "destroy a workflow" do
            assert_equal @old_count-1, LabInterface::Workflow.count
            assert_redirected_to workflows_path
          end
        end
      end
    end

    context "#stage" do
      setup do
        @pipeline = Factory :pipeline, :name => "Generic workflow"
        @ws1      = @pipeline.workflow  # :item_limit => 5

        @ws2 = Factory(:pipeline, :name => 'Old workflow').workflow

        @batch = @pipeline.batches.create!

        @task1 = Factory :task, :name => "Q20 Check", :location => "", :workflow => @ws1, :sorted => 0, :sti_type => "SetDescriptorsTask"
        @task2 = Factory :task, :name => "Submit batch", :location => "http://someurl", :workflow => @ws1, :sorted => 1, :sti_type => "SetDescriptorsTask"
        @task3 = Factory :task, :name => "Q20 Check", :location => "", :workflow => @ws2, :sorted => 0, :sti_type => "SetDescriptorsTask"
        @task4 = Factory :task, :name => "Submit batch", :location => "http://someurl", :workflow => @ws2 , :sorted => 1, :sti_type => "SetDescriptorsTask"
        @library1 = Factory :library_tube
        @lane1  = Factory :lane
        @lane1.parents << @library1
        @library2 = Factory :library_tube
        @lane2  = Factory :lane
        @lane2.parents << @library2

        @item1 = @pipeline.request_types.last.create!(:asset => @library1, :target_asset => @lane1)
        @batch.batch_requests.create!(:request => @item1, :position => 1)
        @item2 = @pipeline.request_types.last.create!(:asset => @library2, :target_asset => @lane2)
        @batch.batch_requests.create!(:request => @item2, :position => 2)

        Factory :descriptor, :task => @task2, :name => "Chip Barcode", :kind => "ExternalBarcode", :selection => {}
        Factory :descriptor, :task => @task2, :name => "Operator", :kind => "Barcode", :selection => {}
        Factory :descriptor, :task => @task2, :name => "Comment", :kind => "Text", :selection => {}
        Factory :descriptor, :task => @task2, :name => "Passed?", :kind => "Selection", :selection => {}


        @user       = Factory :admin
        @controller.stubs(:current_user).returns(@user)
        @batch_events_size = @batch.lab_events.size
      end

      context "should set descriptors on batch" do
        setup do

          # Check the requests
          request_data = @batch.requests(true).map { |r| r.id }.inject({}) { |result, element| result[element.to_s] = "1" ; result }
          post  "stage"  , {:controller=>"workflows", :id => 0, :action => "stage","next_stage"=>"true", "fields"=>{"1"=>"Passed?", "2"=>"Operator", "3"=>"Chip Barcode", "4"=>"Comment"}, "descriptors"=>{"Comment"=>"Some Comment", "Chip Barcode"=>"3290000006714", "Operator"=>"2470000002799", "Passed?"=>"Yes"}, :batch_id => @batch.id,  :workflow_id => @ws1.id, :request => request_data}
        end

        should_change('batch.lab_events', :by => 1) { Batch.find(@batch.id).lab_events.size }

        should "change number of events on batch" do
          assert_equal "Complete", Batch.find(@batch.id).lab_events.last.description
        end

      end
    end

    context "#duplicate" do
      setup do
        @workflow = Factory(:pipeline).workflow
        get :duplicate, :id => @workflow.id.to_s
      end

      should_respond_with :redirect
    end

    context "#reorder_tasks" do
      setup do
        @workflow = Factory(:pipeline).workflow
        get :reorder_tasks, :id => @workflow.id.to_s
      end

      should_respond_with :success
    end

    context "#sort" do
      setup do
        @workflow = Factory(:pipeline).workflow
        # Err. WorkflowsController. Why is this not just id??
        get :sort, :workflow_id => @workflow.id.to_s
      end

      should_respond_with :success
    end
  end
end
