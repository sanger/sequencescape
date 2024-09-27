# frozen_string_literal: true

require 'test_helper'

class AssetLinkTest < ActiveSupport::TestCase
  context 'AssetLink::Job' do
    setup do
      @source_tube = create(:tube)
      @destination_tube = create(:tube)
      @job_count = Delayed::Job.count
      AssetLink::Job.create(@source_tube, [@destination_tube])
    end

    should 'create a job' do
      assert_equal 1, Delayed::Job.count - @job_count
    end

    context 'When processed' do
      setup { Delayed::Worker.new.work_off }

      should 'create a link' do
        assert_includes @destination_tube.reload.parents, @source_tube
      end

      should 'remove the job from the queue' do
        assert_equal 0, Delayed::Job.count - @job_count
      end
    end
  end
end
