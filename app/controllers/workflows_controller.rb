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
  before_action :find_workflow_by_id, only: %i[show batches]

  attr_accessor :plate_purpose_options, :spreadsheet_layout, :batch

  include Tasks::AddSpikedInControlHandler
  include Tasks::AssignTagsHandler
  include Tasks::AssignTagsToTubesHandler
  include Tasks::AssignTubesToWellsHandler
  include Tasks::BindingKitBarcodeHandler
  include Tasks::CherrypickHandler
  include Tasks::MovieLengthHandler
  include Tasks::PlateTemplateHandler
  include Tasks::PlateTransferHandler
  include Tasks::PrepKitBarcodeHandler
  include Tasks::SamplePrepQcHandler
  include Tasks::SetDescriptorsHandler
  include Tasks::SetCharacterisationDescriptorsHandler
  include Tasks::TagGroupHandler
  include Tasks::ValidateSampleSheetHandler
  include Tasks::StartBatchHandler

  # Lists all the workflows
  # @note JG: While this works, I don't think it is used.
  # @todo Remove (Including route)
  def index
    @workflows = Workflow.all

    respond_to do |format|
      format.html
      format.xml { render xml: @workflows.to_xml }
    end
  end

  # Shows a summary of the steps within a workflow
  # @note JG: This is a remnant from when workflows were user editable. I don't believe it is used
  #       and while it doesn't throw exceptions, its output is likely misleading for many pipelines.
  # @todo Remove (Including route)
  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @workflow.to_xml }
    end
  end

  # Presumably used to list all batches associated with a workflow
  # Not listed in routes
  # @todo Remove
  def batches
    @workflow = Workflow.find(params[:id])
    # TODO: association broken here - something to do with the attachables polymorph?
    @batches = Batch.where(workflow_id: @workflow.id).sort_by(&:id).reverse
  end

  # Appears to be remnant of workflow editing? Shouldn't be in use any more.
  # @todo Remove (Including route, which doesn't even seem to match up properly).
  #       Also tested in workflows_controller_test.rb, but that test can be removed.
  def sort
    @workflow = Workflow.find(params[:workflow_id])
    @task_list = @workflow.tasks
    @task_list.each do |task|
      task.sorted = params['task_list'].index(task.id.to_s) + 1
      task.save
    end
    head :ok
  end

  # TODO: This needs to be made RESTful.
  # 1: Routes need to be refactored to provide more sensible urls
  # 2: We call them tasks in the code, and stages in the URL. They should be consistent
  # 3: This endpoint currently does two jobs, executing the current task, and rendering the next
  # 4: Some tasks rely on parameters passed in from the previous task. This isn't ideal, but it might
  #    be worth maintaining the behaviour until we solve the problems.
  # 5: We need to improve the repeatability of tasks.
  # 6: GET should be Idempotent. doing a task should be a POST
  def stage
    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @stage = params[:id].to_i
    @task = @workflow.tasks[@stage]
    # If params[:next_stage] is nil then just render the current task
    # else actually execute the task.
    unless params[:next_stage].nil?

      eager_loading = @task.included_for_do_task
      @batch ||= Batch.includes(eager_loading).find(params[:batch_id])

      unless @batch.editable?
        flash[:error] = 'You cannot make changes to a completed batch.'
        redirect_back fallback_location: root_path
        return false
      end

      ActiveRecord::Base.transaction do
        if @task.do_task(self, params)
          # Task completed, start the batch is necessary and display the next one
          do_start_batch_task(@task, params)
          @stage += 1
          params[:id] = @stage
          @task = @workflow.tasks[@stage]
        end
      end
    end

    # Is this the last task in the workflow?
    if @stage >= @workflow.tasks.size
      # All requests have finished all tasks: finish workflow
      redirect_to finish_batch_url(@batch)
    else
      if @batch.nil? || @task.included_for_render_task != eager_loading
        @batch = Batch.includes(@task.included_for_render_task).find(params[:batch_id])
      end
      @task.render_task(self, params)
    end
  end

  # Default render taks activity, eg. from {Task#render_task}
  def render_task(task, params)
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.requests

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = task
  end

  private

  def ordered_fields(fields)
    response = Array.new
    fields.keys.sort_by(&:to_i).each do |key|
      response.push fields[key]
    end
    response
  end

  # Flattens nested hashes down into a single layer in a similar manner
  # to rails form parameter naming.
  # @example Flattening a hash multiple levels deep
  #   flatten_hash(key: 'value', key2: { key2a: 'value2a', key2b: 'value2b', key2c: { nested: 'deep'}})
  #   # => {"key"=>"value", "key2[key2a]"=>"value2a", "key2[key2b]"=>"value2b", "key2[key2c][nested]"=>"deep"}
  #
  # @example Flattening a hash with ancestors
  #   flatten_hash({key: 'value', key2: { key2a: 'value2a', key2b: 'value2b'}}, [:ancestor])
  # # => {"ancestor[key]"=>"value", "ancestor[key2][key2a]"=>"value2a", "ancestor[key2][key2b]"=>"value2b"}
  #
  # @param hash [Hash] The hash to flatten
  # @param ancestor_names [Array] Ancestors for all keys in the hash
  #
  # @return [type] [description]
  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += '[]' if v.is_a?(Array)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end

  def find_workflow_by_id
    @workflow = Workflow.find(params[:id])
  end

  def eventify_batch(batch, task)
    event = batch.lab_events.build(
      description: 'Complete',
      user: current_user,
      batch: batch
    )
    event.add_descriptor Descriptor.new(name: 'task_id', value: task.id)
    event.add_descriptor Descriptor.new(name: 'task', value: task.name)
    event.save!
  end
end
