# frozen_string_literal: true

require 'test_helper'

ActionController::TestCase.include AuthenticatedTestHelper

class WorkflowsControllerTest < ActionController::TestCase
  context 'WorkflowController' do
    setup do
      @controller = WorkflowsController.new
      @request    = ActionController::TestRequest.create(@controller)

      @user = FactoryBot.create :user
      session[:user] = @user.id
      @pipeline_user = FactoryBot.create :pipeline_admin
    end
    should_require_login

    context '#index' do
      setup do
        get :index
      end

      should respond_with :success
    end

    context '#stage' do
      setup do
        @pipeline = FactoryBot.create :pipeline, name: 'Generic workflow'
        @ws1      = @pipeline.workflow # :item_limit => 5

        @ws2 = FactoryBot.create(:pipeline, name: 'Old workflow').workflow

        @batch = @pipeline.batches.create!

        @task1 = FactoryBot.create :task, name: 'Q20 Check', location: '', workflow: @ws1, sorted: 0, sti_type: 'SetDescriptorsTask'
        @task2 = FactoryBot.create :task, name: 'Submit batch', location: 'http://someurl', workflow: @ws1, sorted: 1, sti_type: 'SetDescriptorsTask'
        @task3 = FactoryBot.create :task, name: 'Q20 Check', location: '', workflow: @ws2, sorted: 0, sti_type: 'SetDescriptorsTask'
        @task4 = FactoryBot.create :task, name: 'Submit batch', location: 'http://someurl', workflow: @ws2, sorted: 1, sti_type: 'SetDescriptorsTask'
        @library1 = FactoryBot.create :library_tube
        @lane1 = FactoryBot.create :lane
        @lane1.labware.parents << @library1
        @library2 = FactoryBot.create :library_tube
        @lane2 = FactoryBot.create :lane
        @lane2.labware.parents << @library2

        @item1 = @pipeline.request_types.last.create!(asset: @library1, target_asset: @lane1)
        @batch.batch_requests.create!(request: @item1, position: 1)
        @item2 = @pipeline.request_types.last.create!(asset: @library2, target_asset: @lane2)
        @batch.batch_requests.create!(request: @item2, position: 2)

        FactoryBot.create :descriptor, task: @task2, name: 'Chip Barcode', kind: 'ExternalBarcode', selection: {}
        FactoryBot.create :descriptor, task: @task2, name: 'Operator', kind: 'Barcode', selection: {}
        FactoryBot.create :descriptor, task: @task2, name: 'Comment', kind: 'Text', selection: {}
        FactoryBot.create :descriptor, task: @task2, name: 'Passed?', kind: 'Selection', selection: {}

        @user = FactoryBot.create :admin
        session[:user] = @user.id
        @batch_events_size = @batch.lab_events.size
      end

      context 'should set descriptors on batch' do
        setup do
          @batch_lab_events = Batch.find(@batch.id).lab_events.size
          request_data = @batch.requests.reload.map(&:id).each_with_object({}) { |element, result| result[element.to_s] = '1' }
          post :stage,
               params: { :controller => 'workflows',
                         :id => 0,
                         :action => 'stage',
                         'next_stage' => 'true',
                         'fields' => { '1' => 'Passed?', '2' => 'Operator', '3' => 'Chip Barcode', '4' => 'Comment' },
                         'descriptors' => { 'Comment' => 'Some Comment', 'Chip Barcode' => '3290000006714', 'Operator' => '2470000002799', 'Passed?' => 'Yes' },
                         :batch_id => @batch.id,
                         :workflow_id => @ws1.id,
                         :request => request_data }
        end

        should 'change batch.lab_events by 1' do
          assert_equal 1, Batch.find(@batch.id).lab_events.size - @batch_lab_events, 'Expected batch.lab_events to change by 1'
        end

        should 'change number of events on batch' do
          assert_equal 'Complete', Batch.find(@batch.id).lab_events.last.description
        end
      end
    end

    context '#sort' do
      setup do
        @workflow = FactoryBot.create(:pipeline).workflow
        # Err. WorkflowsController. Why is this not just id??
        get :sort, params: { workflow_id: @workflow.id.to_s }
      end

      should respond_with :success
    end
  end
end
