class SubmissionWorkflowsController < ApplicationController
  before_filter :admin_login_required

  # GET /submission_workflows
  # GET /submission_workflows.xml
  def index
    @submission_workflows = Submission::Workflow.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @submission_workflows }
    end
  end

  # GET /submission_workflows/1
  # GET /submission_workflows/1.xml
  def show
    @submission_workflow = Submission::Workflow.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @submission_workflow }
    end
  end

  # GET /submission_workflows/new
  # GET /submission_workflows/new.xml
  def new
    @submission_workflow = Submission::Workflow.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @submission_workflow }
    end
  end

  # GET /submission_workflows/1/edit
  def edit
    @submission_workflow = Submission::Workflow.find(params[:id])
  end

  # POST /submission_workflows
  # POST /submission_workflows.xml
  def create
    @submission_workflow = Submission::Workflow.new(params[:submission_workflow])

    respond_to do |format|
      if @submission_workflow.save
        flash[:notice] = 'Submission::Workflow was successfully created.'
        format.html { redirect_to(@submission_workflow) }
        format.xml  { render :xml => @submission_workflow, :status => :created, :location => @submission_workflow }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @submission_workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /submission_workflows/1
  # PUT /submission_workflows/1.xml
  def update
    @submission_workflow = Submission::Workflow.find(params[:id])

    respond_to do |format|
      if @submission_workflow.update_attributes(params[:submission_workflow])
        flash[:notice] = 'Submission::Workflow was successfully updated.'
        format.html { redirect_to(@submission_workflow) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @submission_workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /submission_workflows/1
  # DELETE /submission_workflows/1.xml
  def destroy
    @submission_workflow = Submission::Workflow.find(params[:id])
    ActiveRecord::Base.transaction do
      @submission_workflow.destroy
    end

    respond_to do |format|
      format.html { redirect_to(submission_workflows_url) }
      format.xml  { head :ok }
    end
  end
end
