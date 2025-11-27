# frozen_string_literal: true
# Controls progress through the {Task tasks} in a {Workflow} as part of
# taking a {Batch} through a {Pipeline}
#
# {#stage} is the main processing step, and responds to *all* HTTP methods.
# The currently active task is supplied by params[:stage]
#
# If params[:next_stage] is nil it will render the page associated with the current
# {Task} using {Task#render_task}
# If params[:next_stage] is present it will perform the current {Task} using {Task#do_task}
# before incrementing the stage and rendering the next task.
# If there are no further tasks present, it will redirect to the finish_batch page.
#
# @note A large amount of the task processing actually occurs within the controller.
#       These methods are included via the various Handler modules.
class WorkflowsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  attr_accessor :plate_purpose_options, :spreadsheet_layout, :batch

  # @todo These actions should be extracted from the controller, and instead be handled by an object invoked
  #       by the task
  include Tasks::CherrypickHandler
  include Tasks::PlateTemplateHandler
  include Tasks::PlateTransferHandler
  include Tasks::SetDescriptorsHandler

  # TODO: This needs to be made RESTful.
  # 1: Routes need to be refactored to provide more sensible urls
  # 2: We call them tasks in the code, and stages in the URL. They should be consistent
  # 3: This endpoint currently does two jobs, executing the current task, and rendering the next
  # 4: Some tasks rely on parameters passed in from the previous task. This isn't ideal, but it might
  #    be worth maintaining the behaviour until we solve the problems.
  # 5: We need to improve the repeatability of tasks.
  # 6: GET should be Idempotent. doing a task should be a POST
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def stage # rubocop:todo Metrics/CyclomaticComplexity
    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @stage = params[:id].to_i
    @task = @workflow.tasks[@stage]

    # If params[:next_stage] is nil then just render the current task
    # else actually execute the task.
    unless params[:next_stage].nil?
      eager_loading = @task.included_for_do_task
      @batch = Batch.includes(eager_loading).find(params[:batch_id])

      editable, message = @task.can_process?(@batch)

      unless editable
        redirect_back_or_to batch_path(@batch), alert: message
        return false
      end

      ActiveRecord::Base.transaction do
        task_success, task_message = @task.do_task(self, params, current_user)
        if task_success
          # Task completed, start the batch is necessary and display the next one
          start_batch
          @stage += 1
          params[:id] = @stage
          @task = @workflow.tasks[@stage]
        end
        flash[task_success ? :notice : :alert] ||= task_message if task_message
      end
    end

    if params[:commit] == 'Update'
      redirect_to batch_path(@batch)
    elsif @stage >= @workflow.tasks.size
      # All requests have finished all tasks: finish workflow
      redirect_to finish_batch_path(@batch)
    else
      if @batch.nil? || @task.included_for_render_task != eager_loading
        @batch = Batch.includes(@task.included_for_render_task).find(params[:batch_id])
      end
      @task.render_task(self, params, current_user)
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  # Default render task activity, eg. from {Task#render_task}
  def render_task(task, params)
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.requests

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = task
  end

  private

  def create_batch_events(batch, task)
    event = batch.lab_events.build(description: 'Complete', user: current_user, batch: batch)
    event.add_descriptor Descriptor.new(name: 'task_id', value: task.id)
    event.add_descriptor Descriptor.new(name: 'task', value: task.name)
    event.save!
  end

  def start_batch
    return unless @task.lab_activity?

    @batch.start!(current_user) if @batch.may_start?
  end
end
