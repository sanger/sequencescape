# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Batch::PipelineBehaviour
  def self.included(base)
    base.class_eval do
      # The associations with the pipeline
      belongs_to :pipeline
      delegate :workflow, :item_limit, :multiplexed?, to: :pipeline
      delegate :tasks, to: :workflow

      # The validations that the pipeline & batch are correct
      validates_presence_of :pipeline

      # Validation of some of the batch information is left to the pipeline that it belongs to
      validate do |record|
        record.pipeline.validation_of_batch(record) if record.pipeline.present?
      end

      # The batch requires positions on it's requests if the pipeline does
      delegate :requires_position?, to: :pipeline

      # Ensure that the batch is valid to be marked as completed
      validate(if: :completed?) do |record|
        record.pipeline.validation_of_batch_for_completion(record)
      end
    end
  end

  def externally_released?
    workflow.source_is_internal? && released?
  end

  def internally_released?
    workflow.source_is_external? && released?
  end

  def show_actions?
    return true if pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline) || pipeline.is_a?(CherrypickForPulldownPipeline)
    !released?
  end

  def has_item_limit?
    item_limit.present?
  end
  alias_method(:has_limit?, :has_item_limit?)

  def complete_events
    @efct ||= if lab_events.loaded
                lab_events.select { |le| le.description == 'Complete' }
              else
                lab_events.where(description: 'Complete')
              end
  end

  def completed_task_ids
    complete_events.map do |event|
      event.descriptor_value_allow_nil('task_id')
    end.compact
  end

  def last_completed_task
    unless complete_events.empty?
      pipeline.workflow.tasks.order(:sorted).where(id: completed_task_ids).last
    end
  end

  def task_for_event(event)
    tasks.detect { |task| task.name == event.description }
  end
end
