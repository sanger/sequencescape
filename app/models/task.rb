# A Task forms part of a {Workflow} which in turn describes the steps that form a
# {Pipeline}. Most tasks are a subclass of Task
#
# @deprecated Task form a large number of legacy pipelines in Sequencescape, however most
# more recent pipelines exist outside of Sequencescape itself.
#
# Tasks have three key methods
# {Task#render_task}: Which handles rendering the form displayed to the user
# {Task#do_task}: Which takes the parameters from the form, and performs the task in question
# {Task#partial}: Inicates which partial to render when displaying the form.
#
# @note A large number of tasks delegate a large portion of their behaviour back to the
# {WorkflowsController}. This behaviour is mostly defined in modules under {Task}.
class Task < ApplicationRecord
  belongs_to :workflow, class_name: 'Workflow', foreign_key: :pipeline_workflow_id
  has_many :descriptors, -> { order('sorter') }, dependent: :destroy

  self.inheritance_column = 'sti_type'

  def partial; end

  # By default, most tasks will only support unreleased batches
  def can_process?(batch, from_previous: false)
    batch.released? ? [false, 'Disabled on released batches'] : [true, nil]
  end

  def included_for_do_task
    %i[requests pipeline lab_events]
  end

  def included_for_render_task
    %i[requests pipeline lab_events]
  end

  def render_task(controller, params)
    controller.render_task(self, params)
  end

  def do_task(_controller, _params)
    raise NotImplementedError, "Please Implement a do_task for #{self.class.name}"
  end

  def find_batch(batch_id)
    Batch.includes(:requests, :pipeline, :lab_events).find(batch_id)
  end

  def find_batch_requests(batch_id)
    find_batch(batch_id).ordered_requests
  end
end
