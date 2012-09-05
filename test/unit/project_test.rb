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
        @quota           = Factory :project_quota, :project => @project, :request_type => @request_type, :limit => 5
        @quota_2         = Factory :project_quota, :project => @project, :request_type => @request_type_2, :limit => 7
        @quota_3         = Factory :project_quota, :project => @project, :request_type => @request_type_3, :limit => 14
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

      context "#Quotas" do
        should "Calculate correctly" do
          assert_equal 4, @project.used_quota(@request_type) # Include pending
          assert_equal 3, @submission.passed_requests(@request_type)
          assert_equal 1, @submission.pending_requests(@request_type)
          assert_equal 1, @project.projected_remaining_quota(@request_type)
          assert_equal 5, @project.total_quota(@request_type)
          assert_equal 5, @project.quota_limit_for(@request_type)
          assert_equal @quota, @project.quota_for(@request_type)
        end

        context "compare_quotas" do
          setup do
            @new_quotas = { "#{@request_type.id}" => "8" }
            @old_quotas = { "#{@request_type.id}" => "5" }
          end

          should "return false because quotas are not equal" do
            assert_equal 5, @project.quota_limit_for(@request_type)
            assert_equal 5, @quota.limit
            assert_equal false, @project.compare_quotas(@new_quotas)
          end

          should "return true because quotas are equal" do
            assert_equal 5, @quota.limit
            assert @project.compare_quotas(@old_quotas)
          end
        end
      end

    end

    context "#has_quota?" do
      setup do
        @project = Factory :project
        @request_type = Factory :request_type
      end
      context "when enforced" do
        setup do
          @project.enforce_quotas = true
        end
        context "and has excess remaining" do
          setup do
            @quota = 10
            @required = 5
            @project.quotas.create(:limit => @quota, :request_type => @request_type)
            @project.project_metadata.budget_division.name = 'MetaHit'
          end
          should "be true" do
            assert @project.has_quota?(@request_type, @required)
          end
        end
        context "and has exact amount remaining" do
          setup do
            @quota = 10
            @required = 10
            @project.quotas.create(:limit => @quota, :request_type => @request_type)
            @project.project_metadata.budget_division.name = 'Small Faculty'
          end
          should "be true" do
            assert @project.has_quota?(@request_type, @required)
          end
        end
        context "and has insufficent remaining" do
          setup do
            @quota = 5
            @required = 10
            @project.quotas.create(:limit => @quota, :request_type => @request_type)
          end
          should "be false" do
            assert ! @project.has_quota?(@request_type, @required)
          end
        end
        context "and has a quota limit set to 0" do
          setup do
            @quota = 0
            @required = 1

            @project.quotas.create(:limit => @quota, :request_type => @request_type)

            assert_equal @quota, @project.projected_remaining_quota(@request_type)
          end
          should "be false" do
            assert ! @project.has_quota?(@request_type, @required)
          end
        end
      end
      context "when not being enforced" do
        setup do
          @project.enforce_quotas = false
        end
        should "be true" do
          assert @project.has_quota?(@request_type, 1000)
        end
      end
      context "with unallocated budget division" do
        setup do
          @project.enforce_quotas = true
          @project.project_metadata.budget_division.name = 'Unallocated'
          @project.save!
          @project.quotas.create(:limit => 2, :request_type => @request_type)
        end

        should 'not be actionable' do
          assert !@project.actionable?
        end

        should 'not have quota for request type' do
          assert !@project.has_quota?(@request_type, 1)
        end
      end
    end
  end
end

