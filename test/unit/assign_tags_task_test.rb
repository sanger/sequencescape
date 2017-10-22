# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class TestWorkflowsController < WorkflowsController
  attr_accessor :batch, :tags, :workflow, :stage
end

class AssignTagsTaskTest < TaskTestBase
  context AssignTagsTask do
    setup do
      # TODO: none of this code tests failure conditions as that causes crashes
      # Basically 'flash' is pulled from 'session[:flash]' which is not configured properly on @workflow
      # @workflow needs 'workflow' and 'stage' set
      # @workflow does not like redirect_to (think this might be shoulda)
      @controller = TestWorkflowsController.new
      @workflow = create :lab_workflow_for_pipeline
      @user = create :user
      # @controller.s[:user] = @user.id
      @pipeline       = create :pipeline
      @batch          = create :batch, pipeline: @pipeline
      @controller.batch = @batch
      @br = create :batch_request
      @batch.batch_requests << @br
      @task      = create :assign_tags_task
      @tag_group = create :tag_group
      @tag       = create :tag, tag_group: @tag_group
    end

    expected_partial('assign_tags_batches')

    context 'check tags group' do
      should 'valid' do
        assert_not_equal [], @tag_group.tags
        assert_equal @tag, @tag_group.tags.find(@tag.id)
      end
    end

    context '#render_task' do
      setup do
        params = { workflow_id: @workflow.id, tag_group: @tag_group.id, batch_id: @batch.id }
        @task.render_task(@controller, params)
      end

      should 'render a specific template' do
        assert_equal @tag_group.tags, @controller.tags
      end
    end

    context '#do_task' do
      setup do
        @multiplexedlibrarytube_count = MultiplexedLibraryTube.count
        @pipeline       = create :pipeline
        @batch          = create :batch, pipeline: @pipeline
        # TODO: Move this into factory. Create library and sample_tube factory
        @sample_tube    = create(:sample_tube)
        @library        = create(:library_tube).tap { |tube| tube.aliquots = @sample_tube.aliquots.map(&:dup) }
        @sample_tube.children << @library

        submission = Submission.last # probably built in batch ...?
        @mx_request = create :request, request_type_id: 1, submission: submission, asset: @sample_tube, target_asset: @library
        $stop = true
        @cf_request = create :request_without_assets, request_type_id: 2, submission: submission, asset: nil
        @batch.requests << [@mx_request, @cf_request]
        @controller.batch = @batch

        params = { workflow_id: @workflow, batch_id: @batch.id,
                   tag_group: @tag_group.id.to_s,
                   mx_library_name: 'MX library',
                   tag: { @mx_request.id.to_s => @tag.id.to_s },
                    }
        @task.do_task(@controller, params)
      end

      should 'have requests in batch' do
        assert_equal 2, @controller.batch.request_count
      end

      should 'change MultiplexedLibraryTube.count by 1' do
        assert_equal 1, MultiplexedLibraryTube.count - @multiplexedlibrarytube_count, 'Expected MultiplexedLibraryTube.count to change by 1'
      end

      should 'should update library' do
        assert_equal 1, @sample_tube.children.size

        # Related to sample tube and tag instance
        assert_equal 1, @library.parents.size
        assert_equal @sample_tube, @library.parent

        # Should have tagged the library tube
        assert_equal @tag_group.tags.first, @library.aliquots.first.tag

        assert_equal 1, MultiplexedLibraryTube.last.parents.size
        assert_equal LibraryTube.find(@library.id), MultiplexedLibraryTube.last.parent
      end
    end
  end
end
