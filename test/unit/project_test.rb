require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  context "Project" do

    context "#billable_events" do
      setup do
        @sample1 = mock("Sample 1", :billable_events => [1, 2, 3])
        @sample2 = mock("Sample 2", :billable_events => [1, 2, 3, 4])

        @project = Project.new :name => "Project : #{Time.now}"
        @project.expects(:samples).returns([@sample1, @sample2])

        @billable_events = @project.billable_events
      end

      should "return an array of billable events" do
        assert_equal 7, @billable_events.size
      end
    end

    context "#billable_events_between" do
      setup do
        # FIXME Does the implementation deal in Times
        from = Time.parse("2008-04-01")
        to = Time.parse("2008-04-15")

        @event1 = mock("Event 1")
        @event1.expects(:created_at).returns(Time.parse("2008-04-15")).times(2)
        @event2 = mock("Event 2")
        @event2.expects(:created_at).returns(Time.parse("2008-04-15")).times(2)
        @event3 = mock("Event 3")
        @event3.expects(:created_at).returns(Time.parse("2008-04-16")).times(2)

        @project = Project.new :name => "Project : #{Time.now}"
        @project.expects(:billable_events).returns([@event1, @event2, @event3])

        @billable_events = @project.billable_events_between from.to_date, to.to_date
      end

      should "return an array of billable events filtered" do
        assert_equal [@event1, @event2], @billable_events
      end
    end

   context "Request" do
      setup do
        @project         = Factory :project
        @request_type    = Factory :request_type
        @request_type_2  = Factory :request_type, :name => "request_type_2", :key => "request_type_2"
        @request_type_3  = Factory :request_type, :name => "request_type_3", :key => "request_type_3"
        @submission       = Factory::submission :project => @project, :asset_group_name => 'to avoid asset errors'
        # Failed
        Factory :cancelled_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :cancelled_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :cancelled_request, :project => @project, :request_type => @request_type, :submission => @submission

        # Failed
        Factory :failed_request, :project => @project, :request_type => @request_type, :submission => @submission
        # Passed
        Factory :passed_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :passed_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :passed_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :passed_request, :project => @project, :request_type => @request_type_2, :submission => @submission
        Factory :passed_request, :project => @project, :request_type => @request_type_3, :submission => @submission
        Factory :passed_request, :project => @project, :request_type => @request_type_3, :submission => @submission
        # Pending
        Factory :pending_request, :project => @project, :request_type => @request_type, :submission => @submission
        Factory :pending_request, :project => @project, :request_type => @request_type_3, :submission => @submission
        @submission.save!
      end

      should "Be valid" do
        assert_valid @project
      end

      should "Calculate correctly" do
        assert_equal 3, @submission.cancelled_requests(@request_type)
        assert_equal 4, @submission.completed_requests(@request_type)
        assert_equal 1, @submission.completed_requests(@request_type_2)
        assert_equal 2, @submission.completed_requests(@request_type_3)
        assert_equal 3, @submission.passed_requests(@request_type)
        assert_equal 1, @submission.failed_requests(@request_type)
        assert_equal 1, @submission.pending_requests(@request_type)
        assert_equal 0, @submission.pending_requests(@request_type_2)
        assert_equal 1, @submission.pending_requests(@request_type_3)
        assert_equal 8, @submission.total_requests(@request_type)
      end

    end

  end
end

