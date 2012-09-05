class PipelinesController < ApplicationController
  before_filter :find_pipeline_by_id, :only => [ :show, :setup_inbox,
                                   :set_inbox, :training_batch, :show_comments, :activate, :deactivate, :destroy, :batches]

  def index
    @pipelines = Pipeline.active.internally_managed.all(:order => "sorter ASC")
    @grouping  = @pipelines.inject(Hash.new { |h,k| h[k] = [] }) { |h,p| h[p.group_name] << p ; h }

    respond_to do |format|
      format.html
      format.xml { render :xml => @pipelines.to_xml}
    end
  end

  def show
    @show_held_requests = (params[:view] == 'all')
    @current_page       = params[:page]

    @pending_batches     = @pipeline.batches.pending_for_ui.includes_for_ui
    @batches_in_progress = @pipeline.batches.in_progress_for_ui.includes_for_ui
    @completed_batches   = @pipeline.batches.completed_for_ui.includes_for_ui
    @released_batches    = @pipeline.batches.released_for_ui.includes_for_ui
    @failed_batches      = @pipeline.batches.failed_for_ui.includes_for_ui

    @batches = @pipeline.batches.all(:limit => 5, :order => "created_at DESC")

    unless @pipeline.qc?
      @information_types = @pipeline.request_information_types
      @requests_waiting  = @pipeline.requests.inbox(@show_held_requests, @current_page, :count)

      if @pipeline.group_by_parent?
        @request_groups = @pipeline.get_input_request_groups(@show_held_requests)
      elsif @pipeline.group_by_submission?
        @grouped_requests  = @pipeline.requests.inbox(@show_held_requests,@current_page).group_by(&:submission_id)
      else
        @requests = @pipeline.requests.inbox(@show_held_requests,@current_page)
      end
    end
  end

  def setup_inbox
    @controls = []
  end

  def set_inbox
    unless params[:controls].blank?
      add_controls(@pipeline, params[:controls])
    end

    if @pipeline.save
      flash[:notice] = "Updated pipeline controls"
      redirect_to pipeline_url(@pipeline)
    else
      flash[:notice] = "Failed to set pipeline controls"
      render :action => "setup_inbox", :id => @pipeline.id
    end
  end

  def training_batch
    @controls = @pipeline.controls
  end

  def show_comments
    hash_group = params[:group]
    unless hash_group
      flash[:error] = "No assets selected"
      redirect_to :controller => :pipelines, :action => :show, :id => @pipeline.id
    end

    if @pipeline.group_by_parent?
      parent_id = hash_group[:parent]
      parent = Asset.find(parent_id)
      @assets = [parent] #+parent.wells

      @requests = @pipeline.get_input_requests_for_group(hash_group)
      @group_name = "#{parent.name}"
    else
      @group_name = hash_grou
    end

  end

  before_filter :prepare_batch_and_pipeline, :only => [ :summary, :finish ]
  def prepare_batch_and_pipeline
    @batch    = Batch.find(params[:id])
    @pipeline = @batch.pipeline
  end
  private :prepare_batch_and_pipeline

  def summary

  end

  def finish
    @batch.complete!(current_user)
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = exception.record.errors.full_messages
    redirect_to(url_for(:controller => 'batches', :action => 'show', :id => @batch.id))
  end

  def release
    ActiveRecord::Base.transaction do
      @batch = Batch.find(params[:id])
      @batch.release!(current_user)
    end

    flash[:notice] = 'Batch released!'
    redirect_to :controller => "batches", :action => "show", :id => @batch.id
  end

  def activate
    @pipeline.active = true
    if @pipeline.save
      flash[:notice] = "Pipeline activated"
      redirect_to pipelines_path
    else
      flash[:notice] = "Failed to activate pipeline"
      redirect_to pipeline_path(@pipeline)
    end
  end

  def deactivate
    @pipeline.active = false
    if @pipeline.save
      flash[:notice] = "Pipeline deactivated"
      redirect_to pipelines_path
    else
      flash[:notice] = "Failed to deactivate pipeline"
      redirect_to pipeline_path(@pipeline)
    end
  end

  def destroy
    unless current_user.is_administrator?
      flash[:error]  = "User #{current_user.name} can't delete pipelines"
      redirect_to :action => "index"
      return
    end

    @pipeline.destroy
    flash[:notice] = "Pipeline deleted"
    redirect_to :action => "index"
  end

  def batches
    @batches = @pipeline.batches.paginate :page => params[:page], :order => 'id DESC'
  end

  # to modify when next_request will be ready
  def update_priority
    request  = Request.find(params[:request_id])
    ActiveRecord::Base.transaction do
      request.update_priority
      render :text => '', :layout => false
    end
  rescue ActiveRecord::RecordInvalid => exception
    render :text => '', :layout => false, :status => :unprocessable_entity
  end

  private
  def find_pipeline_by_id
    @pipeline = Pipeline.find(params["id"])
  end

  def add_controls(pipeline, controls)
    controls.each do |control|
      values = control.split(",")
      unless Control.exists?(:item_id => values.last, :pipeline_id => pipeline.id)
        pipeline.controls.create(:name => values.first, :item_id => values.last, :pipeline_id => pipeline.id)
      end
    end
  end
end
