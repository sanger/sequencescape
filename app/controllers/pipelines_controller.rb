class PipelinesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_pipeline_by_id, only: [:show, :setup_inbox, :set_inbox, :activate, :deactivate, :destroy, :batches]
  before_action :lab_manager_login_required, only: [:update_priority, :deactivate, :activate]
  before_action :prepare_batch_and_pipeline, only: [:summary, :finish]

  after_action :set_cache_disabled!, only: [:show]

  def index
    @pipelines = Pipeline.active.internally_managed.alphabetical
    @grouping = @pipelines.group_by(&:group_name)

    respond_to do |format|
      format.html
      format.xml { render xml: @pipelines.to_xml }
    end
  end

  def show
    expires_now
    @show_held_requests = (params[:view] == 'all')
    @current_page       = params[:page]

    @pending_batches     = @pipeline.batches.pending_for_ui.includes_for_ui
    @batches_in_progress = @pipeline.batches.in_progress_for_ui.includes_for_ui
    @completed_batches   = @pipeline.batches.completed_for_ui.includes_for_ui
    @released_batches    = @pipeline.batches.released_for_ui.includes_for_ui
    @failed_batches      = @pipeline.batches.failed_for_ui.includes_for_ui

    @batches = @last5_batches = @pipeline.batches.latest_first.includes_for_ui

    @information_types = @pipeline.request_information_types.shown_in_inbox
    @requests_waiting  = @pipeline.requests.inbox(@show_held_requests, @current_page, :count)

    if @pipeline.group_by_parent?
      # We use the inbox presenter
      @inbox_presenter = Presenters::GroupedPipelineInboxPresenter.new(@pipeline, current_user, @show_held_requests)
    elsif @pipeline.group_by_submission?
      requests = @pipeline.requests.inbox(@show_held_requests, @current_page)
      @grouped_requests = requests.group_by(&:submission_id)
      @requests_comment_count = Comment.counts_for(requests)
      @assets_comment_count = Comment.counts_for(requests.map(&:asset))
    else
      @requests = @pipeline.requests.inbox(@show_held_requests, @current_page)
      # We convert to an array here as otherwise tails tries to be smart
      # and use the scope. Not only does it fail, but we may as well cache
      # the result now anyway.
      @requests_comment_count = Comment.counts_for(@requests.to_a)
      @assets_comment_count = Comment.counts_for(@requests.map(&:asset))
      @requests_samples_count = Request.where(id: @requests.to_a).joins(:samples).group(:id).count
    end
  end

  def setup_inbox
    @controls = []
  end

  def set_inbox
    add_controls(@pipeline, params[:controls]) if params[:controls].present?

    if @pipeline.save
      flash[:notice] = 'Updated pipeline controls'
      redirect_to pipeline_url(@pipeline)
    else
      flash[:notice] = 'Failed to set pipeline controls'
      render action: 'setup_inbox', id: @pipeline.id
    end
  end

  def summary; end

  def finish
    ActiveRecord::Base.transaction { @batch.complete!(current_user) }
  rescue ActiveRecord::RecordInvalid => exception
    flash[:error] = exception.record.errors.full_messages
    redirect_to(url_for(controller: 'batches', action: 'show', id: @batch.id))
  end

  def release
    ActiveRecord::Base.transaction do
      @batch = Batch.find(params[:id])
      @batch.release!(current_user)
    end

    flash[:notice] = 'Batch released!'
    redirect_to controller: 'batches', action: 'show', id: @batch.id
  end

  def activate
    @pipeline.active = true
    if @pipeline.save
      flash[:notice] = 'Pipeline activated'
      redirect_to pipelines_path
    else
      flash[:notice] = 'Failed to activate pipeline'
      redirect_to pipeline_path(@pipeline)
    end
  end

  def deactivate
    @pipeline.active = false
    if @pipeline.save
      flash[:notice] = 'Pipeline deactivated'
      redirect_to pipelines_path
    else
      flash[:notice] = 'Failed to deactivate pipeline'
      redirect_to pipeline_path(@pipeline)
    end
  end

  def batches
    @batches = @pipeline.batches.order(id: :desc).page(params[:page])
  end

  # to modify when next_request will be ready
  def update_priority
    request  = Request.find(params[:request_id])
    ActiveRecord::Base.transaction do
      request.update_priority
      render plain: '', layout: false
    end
  rescue ActiveRecord::RecordInvalid => _exception
    render plain: '', layout: false, status: :unprocessable_entity
  end

  private

  def prepare_batch_and_pipeline
    @batch    = Batch.find(params[:id])
    @pipeline = @batch.pipeline
  end

  def find_pipeline_by_id
    @pipeline = Pipeline.find(params['id'])
  end

  def add_controls(pipeline, controls)
    controls.each do |control|
      values = control.split(',')
      unless Control.exists?(item_id: values.last, pipeline_id: pipeline.id)
        pipeline.controls.create(name: values.first, item_id: values.last, pipeline_id: pipeline.id)
      end
    end
  end
end
