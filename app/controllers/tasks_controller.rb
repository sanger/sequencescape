# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class TasksController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_tasks_by_id, only: [:show, :edit, :update, :destroy]

  def index
    @tasks = Task.all

    respond_to do |format|
      format.html
      format.xml { render xml: @tasks.to_xml }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @task.to_xml }
    end
  end

  def new
    @task = SetDescriptorsTask.new
    @workflow = LabInterface::Workflow.find(params[:workflow_id])
    @task.descriptors << Descriptor.new(name: '', value: '')
    @count = @task.descriptors.size
  end

  def new_field
    render partial: 'descriptor', locals: { field: Descriptor.new, field_number: params[:id] }
  end

  def new_option
    render partial: 'option', locals: { field: Descriptor.new, field_number: params[:id], option_number: params[:option], name: '' }
  end

  def edit
    @count = @task.descriptors.size
  end

  def create
    params[:task][:pipeline_workflow_id] = params[:task].delete(:workflow_id)
    @task = SetDescriptorsTask.new(params[:task])

    respond_to do |format|
      if @task.save
        @task.create_descriptors(params[:descriptor])

        flash[:notice] = 'Task was successfully created.'
        format.html { redirect_to task_url(@task) }
        format.xml  { head :created, location: task_url(@task) }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @task.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @task.update_attributes(params[:task])
        @task.update_descriptors(params[:descriptor])

        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to task_url(@task) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @task.errors.to_xml }
      end
    end
  end

  def destroy
    @task.destroy

    respond_to do |format|
      format.html { redirect_to tasks_url }
      format.xml  { head :ok }
    end
  end

  def find_tasks_by_id
    @task = Task.find(params[:id])
  end
end
