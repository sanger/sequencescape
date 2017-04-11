# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  context 'Project' do
    should validate_presence_of :name

    context '#metadata' do
      setup do
        @project = Project.new name: "Project : #{Time.now}"
      end

      should 'require cost-code and project funding model' do
        assert_equal false, @project.project_metadata.valid?, 'Validation not working'
        assert_equal false, @project.valid?, 'Validation not delegating'
        assert_equal false, @project.save, 'Save behaving badly'
        assert @project.errors.full_messages.include?("Project metadata project cost code can't be blank")
      end
    end

    context '#billable_events' do
      setup do
        @sample1 = mock('Sample 1', billable_events: [1, 2, 3])
        @sample2 = mock('Sample 2', billable_events: [1, 2, 3, 4])

        @project = Project.new name: "Project : #{Time.now}"
        @project.expects(:samples).returns([@sample1, @sample2])

        @billable_events = @project.billable_events
      end

      should 'return an array of billable events' do
        assert_equal 7, @billable_events.size
      end
    end

    context '#billable_events_between' do
      setup do
        # FIXME: Does the implementation deal in Times
        from = Time.parse('2008-04-01')
        to = Time.parse('2008-04-15')

        @event1 = mock('Event 1')
        @event1.expects(:created_at).returns(Time.parse('2008-04-15')).times(2)
        @event2 = mock('Event 2')
        @event2.expects(:created_at).returns(Time.parse('2008-04-15')).times(2)
        @event3 = mock('Event 3')
        @event3.expects(:created_at).returns(Time.parse('2008-04-16')).times(2)

        @project = Project.new name: "Project : #{Time.now}"
        @project.expects(:billable_events).returns([@event1, @event2, @event3])

        @billable_events = @project.billable_events_between from.to_date, to.to_date
      end

      should 'return an array of billable events filtered' do
        assert_equal [@event1, @event2], @billable_events
      end
    end

   context 'Request' do
      setup do
        @project         = create :project
        @request_type    = create :request_type
        @request_type_2  = create :request_type, name: 'request_type_2', key: 'request_type_2'
        @request_type_3  = create :request_type, name: 'request_type_3', key: 'request_type_3'
        @submission = FactoryHelp::submission project: @project, asset_group_name: 'to avoid asset errors'
        # Failed
        create :cancelled_request, project: @project, request_type: @request_type, submission: @submission
        create :cancelled_request, project: @project, request_type: @request_type, submission: @submission
        create :cancelled_request, project: @project, request_type: @request_type, submission: @submission

        # Failed
        create :failed_request, project: @project, request_type: @request_type, submission: @submission
        # Passed
        create :passed_request, project: @project, request_type: @request_type, submission: @submission
        create :passed_request, project: @project, request_type: @request_type, submission: @submission
        create :passed_request, project: @project, request_type: @request_type, submission: @submission
        create :passed_request, project: @project, request_type: @request_type_2, submission: @submission
        create :passed_request, project: @project, request_type: @request_type_3, submission: @submission
        create :passed_request, project: @project, request_type: @request_type_3, submission: @submission
        # Pending
        create :pending_request, project: @project, request_type: @request_type, submission: @submission
        create :pending_request, project: @project, request_type: @request_type_3, submission: @submission
        @submission.save!
      end

      should 'Be valid' do
        assert @project.valid?
      end

      should 'Calculate correctly' do
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
