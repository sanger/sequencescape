module Batch::PipelineBehaviour
  def self.included(base)
    base.class_eval do
      # The associations with the pipeline
      belongs_to :pipeline
      attr_protected :pipeline_id
      delegate :workflow, :item_limit, :multiplexed?, :to => :pipeline
      delegate :tasks, :to => :workflow

      # The validations that the pipeline & batch are correct
      validates_presence_of :pipeline

      # Validation of some of the batch information is left to the pipeline that it belongs to
      validate do |record|
        record.pipeline.validation_of_batch(record) if record.pipeline.present?
      end

      # The batch requires positions on it's requests if the pipeline does
      delegate :requires_position?, :to => :pipeline

      # Ensure that the batch is valid to be marked as completed
      validate(:if => :completed?) do |record|
        record.pipeline.validation_of_batch_for_completion(record)
      end
    end
  end

  def externally_released?
    workflow.source_is_internal? && self.released?
  end

  def internally_released?
    workflow.source_is_external? && self.released?
  end

  def show_actions?
    return true if pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline) || pipeline.is_a?(CherrypickForPulldownPipeline)
    !released?
  end

  def has_item_limit?
    self.item_limit.present?
  end
  alias_method(:has_limit?, :has_item_limit?)

  def events_for_completed_tasks
    self.lab_events.select{ |le| le.description == "Complete" }
  end

  def tasks_for_completed_task_events(events)
    completed_tasks = []
    events.each do |event|
      task_id = event.descriptors.detect{ |d| d.name == "task_id" }
      if task_id
        begin
          task = Task.find(task_id.value)
        rescue ActiveRecord::RecordNotFound
          return []
        end
        unless task.nil?
          completed_tasks << task
        end
      end
    end
    completed_tasks
  end

  def last_completed_task
    unless self.events_for_completed_tasks.empty?
      completed_tasks = self.tasks_for_completed_task_events(self.events_for_completed_tasks)
      tasks = self.pipeline.workflow.tasks
      tasks.sort!{ |a, b| b.sorted <=> a.sorted }
      tasks.each do |task|
        if completed_tasks.include?(task)
          return task
        end
      end
      return nil
    end
  end

  def task_for_event(event)
    tasks.detect { |task| task.name == event.description }
  end

end
