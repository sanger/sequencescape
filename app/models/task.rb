# frozen_string_literal: true
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
  has_many :descriptors, -> { order(:sorter) }, dependent: :destroy

  self.inheritance_column = 'sti_type'

  def partial
  end

  #
  # Indicates if a task can be performed.
  # By default, most tasks will only support unreleased batches
  #
  # @param batch [Batch] The batch on which the action will be performed
  #
  # @return [Array<Bool,String>] Array indicating if the action can be performed.
  #                              Second element is a message about why the action is prevented
  #
  def can_process?(batch)
    batch.released? ? [false, 'Disabled on released batches'] : [true, nil]
  end

  #
  # Indicates if a task can be linked to directly from the batch show page
  # For most tasks this dependent on whether the task can be performed, but some tasks are
  # dependent on the previous task, or are even directly coupled to it.
  #
  # @param batch [Batch] The batch on which the action will be performed
  #
  # @return [Array<Bool,String>] Array indicating if the action can be performed.
  #                              Second element is a message about why the action is prevented
  #
  def can_link_directly?(batch)
    can_process?(batch)
  end

  def included_for_do_task
    %i[requests pipeline lab_events]
  end

  def included_for_render_task
    %i[requests pipeline lab_events]
  end

  def render_task(workflows_controller, params, _user)
    workflows_controller.render_task(self, params)
  end

  def do_task(_workflows_controller, _params, _user)
    raise NotImplementedError, "Please Implement a do_task for #{self.class.name}"
  end
end
