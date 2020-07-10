class PipelinesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :find_pipeline_by_id, only: %i[show activate deactivate destroy batches]
  before_action :lab_manager_login_required, only: %i[update_priority deactivate activate]
  before_action :prepare_batch_and_pipeline, only: %i[summary finish]

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

    @pending_batches     = @pipeline.batches.pending_for_ui.includes_for_ui
    @batches_in_progress = @pipeline.batches.in_progress_for_ui.includes_for_ui
    @completed_batches   = @pipeline.batches.completed_for_ui.includes_for_ui
    @released_batches    = @pipeline.batches.released_for_ui.includes_for_ui
    @failed_batches      = @pipeline.batches.failed_for_ui.includes_for_ui

    @batches = @last5_batches = @pipeline.batches.latest_first.includes_for_ui

    @information_types = @pipeline.request_information_types.shown_in_inbox

    if @pipeline.group_by_parent?
      Rails.logger.info('Pipeline grouped by parent')
      # We use the inbox presenter
      @inbox_presenter = Presenters::GroupedPipelineInboxPresenter.new(@pipeline, current_user, @show_held_requests)
      @requests_waiting = @inbox_presenter.requests_waiting
    elsif @pipeline.group_by_submission?
      Rails.logger.info('Pipeline grouped by submision')
      # Convert to an array now as otherwise the comments counter attempts to be too clever
      # and treats the requests like a scope. Not only does this result in a more complicated
      # query, but also an invalid one
      @requests_waiting = @pipeline.request_count_in_inbox(@show_held_requests)
      requests = @pipeline.requests_in_inbox(@show_held_requests).to_a
      @grouped_requests = requests.group_by(&:submission_id)
      @requests_comment_count = Comment.counts_for(requests)
      @assets_comment_count = Comment.counts_for(requests.map(&:asset))
    else
      Rails.logger.info('Pipeline fallback behaviour')
      @requests_waiting = @pipeline.request_count_in_inbox(@show_held_requests)
      @requests = @pipeline.requests_in_inbox(@show_held_requests).to_a
      # We convert to an array here as otherwise rails tries to be smart
      # and use the scope. Not only does it fail, but we may as well cache
      # the result now anyway.
      @requests_comment_count = Comment.counts_for(@requests)
      @assets_comment_count = Comment.counts_for(@requests.map(&:asset))
      @requests_samples_count = Request.where(id: @requests).joins(:samples).group(:id).count
    end
  end

  def summary; end

  def finish
    ActiveRecord::Base.transaction { @batch.complete!(current_user) }
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.record.errors.full_messages
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
    request = Request.find(params[:request_id])
    ActiveRecord::Base.transaction do
      request.update_priority
      render plain: '', layout: false
    end
  rescue ActiveRecord::RecordInvalid => e
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
end
