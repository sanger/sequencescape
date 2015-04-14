#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014 Genome Research Ltd.
class WorkflowsController < ApplicationController
  before_filter :find_workflow_by_id, :only =>[:auto_batch, :show, :edit, :duplicate, :batches, :update, :destroy, :reorder_tasks]

  include Tasks::AddSpikedInControlHandler
  include Tasks::AssignPlatePurposeHandler
  include Tasks::AssignTagsHandler
  include Tasks::AssignTagsToWellsHandler
  include Tasks::AssignTubesToWellsHandler
  include Tasks::AttachInfiniumBarcodeHandler
  include Tasks::BindingKitBarcodeHandler
  include Tasks::CherrypickGroupBySubmissionHandler
  include Tasks::CherrypickHandler
  include Tasks::DnaQcHandler
  include Tasks::GenerateManifestHandler
  include Tasks::MovieLengthHandler
  include Tasks::PlateTemplateHandler
  include Tasks::PlateTransferHandler
  include Tasks::PrepKitBarcodeHandler
  include Tasks::ReferenceSequenceHandler
  include Tasks::SamplePrepQcHandler
  include Tasks::SetDescriptorsHandler
  include Tasks::SetCharacterisationDescriptorsHandler
  include Tasks::SetLocationHandler
  include Tasks::TagGroupHandler
  include Tasks::ValidateSampleSheetHandler
  include Tasks::StartBatchHandler
  include Tasks::StripTubeCreationHandler

  def index
    @workflows = LabInterface::Workflow.all

    respond_to do |format|
      format.html
      format.xml { render :xml => @workflows.to_xml}
    end
  end

  def auto_batch
    @batch = Batch.find(params[:batch_id])
  end

  public

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @workflow.to_xml }
    end
  end

  def new
    @workflow = LabInterface::Workflow.new
  end

  def edit
  end

  def duplicate
    if @workflow.deep_copy
      flash[:notice] = 'Workflow was successfully duplicated.'
    else
      flash[:error] = 'Something has gone wrong.'
    end
    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml  { head :ok }
    end
  end

  def batches
    @workflow = LabInterface::Workflow.find(params[:id])
    #TODO association broken here - something to do with the attachables polymorph?
    @batches = Batch.find_all_by_workflow_id(@workflow.id).sort_by {|batch| batch.id}.reverse
  end

  def create
    @workflow = LabInterface::Workflow.new(params[:workflow])

    respond_to do |format|
      if @workflow.save
        flash[:notice] = 'Workflow was successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :created, :location => workflow_url(@workflow) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])
        flash[:notice] = 'Workflow was successfully updated.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
    end
  end

  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml  { head :ok }
    end
  end

  def reorder_tasks
  end

  def sort
    @workflow = LabInterface::Workflow.find(params[:workflow_id])
    @task_list = @workflow.tasks
    @task_list.each do |task|
      task.sorted = params['task_list'].index(task.id.to_s) + 1
      task.save
    end
    render :nothing => true
  end

  def stage
    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
    @stage = params[:id].to_i
    @task = @workflow.tasks[@stage]
    @batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])

    if params[:next_stage].present? && !@batch.editable?
      flash[:error] = "You cannot execute more tasks in a completed batch."
      redirect_to :back
      return
    end

    ActiveRecord::Base.transaction do
      # If params[:next_stage] is nil then just render the current task
      # else actually execute the task.
      unless params[:next_stage].nil?
        if @task.do_task(self, params)
          # Task completed, start the batch is necessary and display the next one
          do_start_batch_task(@task,params)
          @stage +=  1
          params[:id] = @stage
          @task = @workflow.tasks[@stage]
        end
      end

      # Is this the last task in the workflow?
      if @stage >= @workflow.tasks.size
        # All requests have finished all tasks: finish workflow
        redirect_to finish_batch_url(@batch)
      else
        @task.render_task(self, params)
      end
    end
  end

  def render_task(task, params)
    @batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
    @requests_by_submission = @requests.group_by(&:submission)

    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
    @task = task
  end

  private

  def ordered_fields(fields)
    response = Array.new
    fields.keys.sort_by{|key| key.to_i}.each do |key|
      response.push fields[key]
    end
    response
  end

  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += "[]" if v.is_a?(Array)
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
    @workflow = LabInterface::Workflow.find(params[:id])
  end

  def eventify_batch(batch, task)
    event = batch.lab_events.create({})
    event.description = "Complete"
    event.add_descriptor Descriptor.new({ :name => 'task_id', :value => task.id })
    event.add_descriptor Descriptor.new({ :name => 'task', :value => task.name })
    event.batch = batch
    event.user  = current_user
    event.save
  end
end
