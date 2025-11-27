# frozen_string_literal: true
module Batch::PipelineBehaviour
  def self.included(base)
    base.class_eval do
      # The associations with the pipeline
      belongs_to :pipeline
      delegate :workflow, :item_limit, to: :pipeline
      delegate :tasks, to: :workflow, allow_nil: true

      # The validations that the pipeline & batch are correct
      validates :pipeline, presence: true

      # Validation of some of the batch information is left to the pipeline that it belongs to
      validate { |record| record.pipeline.presence&.validation_of_batch(record) }

      # The batch requires positions on it's requests if the pipeline does
      delegate :requires_position?, to: :pipeline
    end
  end

  def has_item_limit?
    item_limit.present?
  end
  alias has_limit? has_item_limit?

  def last_completed_task
    pipeline.workflow.tasks.order(:sorted).where(id: completed_task_ids).last unless complete_events.empty?
  end

  private

  def complete_events
    @efct ||=
      if lab_events.loaded
        lab_events.select { |le| le.description == 'Complete' }
      else
        lab_events.where(description: 'Complete')
      end
  end

  def completed_task_ids
    complete_events.filter_map { |lab_event| lab_event.descriptor_hash['task_id'] }
  end
end
