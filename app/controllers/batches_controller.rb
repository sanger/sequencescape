# frozen_string_literal: true

class BatchesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.

  before_action :evil_parameter_hack!

  before_action :login_required, except: %i[released qc_criteria]
  before_action :find_batch_by_id, only: %i[
    show edit update qc_information qc_batch save fail
    fail_batch control add_control print_labels print_plate_labels print_multiplex_labels
    print verify verify_tube_layout reset_batch previous_qc_state filtered swap
    download_spreadsheet gwl_file pacbio_sample_sheet sample_prep_worksheet
  ]
  before_action :find_batch_by_batch_id, only: %i[sort print_multiplex_barcodes print_pulldown_multiplex_tube_labels print_plate_barcodes print_barcodes]

  def index
    if logged_in?
      @user = current_user
      @batches = Batch.where(assignee_id: @user).or(Batch.where(user_id: @user)).order(id: :desc).page(params[:page])
    else
      # Can end up here with XML. And it causes pain.
      @batches = Batch.order(id: :asc).page(params[:page]).limit(10)
    end
    respond_to do |format|
      format.html
      format.xml { render xml: @batches.to_xml }
      format.json { render json: @batches.to_json.gsub(/null/, '""') }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @submenu_presenter = Presenters::BatchSubmenuPresenter.new(current_user, @batch)

        @pipeline = @batch.pipeline
        @tasks    = @batch.tasks.sort_by(&:sorted)
        @rits = @pipeline.request_information_types
        @input_assets = []
        @output_assets = []

        if @pipeline.group_by_parent
          @input_assets = @batch.input_group
          @output_assets = @batch.output_group_by_holder unless @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
        end
      end
      format.xml { render layout: false }
    end
  end

  def edit
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests.includes(:batch_request, :asset, :target_asset, :comments)
    @users = User.all
    @controls = @batch.pipeline.controls
  end

  def update
    if batch_parameters[:assignee_id]
      user = User.find(batch_parameters[:assignee_id])
      assigned_message = "Assigned to #{user.name} (#{user.login})."
    else
      assigned_message = ''
    end

    respond_to do |format|
      if @batch.update(batch_parameters)
        flash[:notice] = "Batch was successfully updated. #{assigned_message}"
        format.html { redirect_to batch_url(@batch) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @batch.errors.to_xml }
      end
    end
  end

  def batch_parameters
    @bp ||= params.require(:batch).permit(:assignee_id)
  end

  def create
    @pipeline = Pipeline.find(params[:id])

    # TODO: These should be different endpoints
    requests = @pipeline.extract_requests_from_input_params(params.to_unsafe_h)

    case params[:action_on_requests]
    when 'cancel_requests'
      transition_requests(requests, :cancel_before_started!, 'Requests cancelled')
    when 'hide_from_inbox'
      transition_requests(requests, :hold!, 'Requests hidden from inbox')
    else
      # This is the standard create action
      standard_create(requests)
    end
  rescue ActiveRecord::RecordInvalid => exception
    respond_to do |format|
      format.html do
        flash[:error] = exception.record.errors.full_messages
        redirect_to(pipeline_path(@pipeline))
      end
      format.xml { render xml: @batch.errors.to_xml }
    end
  end

  def pipeline
    # All pipline batches routes should just direct to batches#index with pipeline and state as filter parameters
    @batches = Batch.where(pipeline_id: params[:pipeline_id] || params[:id]).order(id: :desc).includes(:user, :pipeline).page(params[:page])
  end

  # Deals with QC failures leaving batches and items statuses intact
  def qc_batch
    @batch.qc_complete

    @batch.batch_requests.each do |br|
      next unless br && params[br.request_id.to_s]

      qc_state = params[br.request_id.to_s]['qc_state']
      target = br.request.target_asset
      if qc_state == 'fail'
        target.set_qc_state('failed')
        EventSender.send_fail_event(br.request_id, '', 'Failed manual QC', @batch.id)
      elsif qc_state == 'pass'
        target.set_qc_state('passed')
        EventSender.send_pass_event(br.request_id, '', 'Passed manual QC', @batch.id)
      end
      target.save
    end

    @batch.release_without_user!

    redirect_to controller: :pipelines, action: :show, id: @batch.qc_pipeline_id
  end

  def pending
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.pending.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def started
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.started.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def released
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])

    @batches = @pipeline.batches.released.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
    respond_to do |format|
      format.html
      format.xml { render layout: false }
    end
  end

  def completed
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.completed.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def failed
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.failed.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def fail
    @fail_reasons = if @batch.workflow.source_is_internal?
                      FAILURE_REASONS['internal']
                    else
                      FAILURE_REASONS['external']
                    end
  end

  def fail_items
    ActiveRecord::Base.transaction do
      fail_params = params.permit(:id, requested_fail: {}, requested_remove: {}, failure: [:reason, :comment, :fail_but_charge])
      fail_and_remover = Batch::RequestFailAndRemover.new(fail_params)
      if fail_and_remover.save
        flash[:notice] = fail_and_remover.notice
      else
        flash[:error] = fail_and_remover.errors.full_messages.join(';')
      end
      redirect_to action: :fail, id: params[:id]
    end
  end

  def sort
    @batch.assign_positions_to_requests!(params['requests_list'].map(&:to_i))
    @batch.rebroadcast
    head :ok
  end

  def save
    redirect_to action: :show, id: @batch.id
  end

  def control
    @rits = @batch.pipeline.request_information_types
    @controls = @batch.pipeline.controls
  end

  def add_control
    @control = Control.find(params[:control][:id])
    control_count = params[:control][:count].to_i

    if control_count > @batch.space_left
      flash[:error] = "Can't assign more than #{@batch.space_left} control to this batch"
      redirect_to action: 'control', id: @batch.id
      return
    elsif control_count < 0
      flash[:error] = 'This batch needs at least one control'
      redirect_to action: 'control', id: @batch.id
      return
    end
    control_count = @batch.add_control(@control.name, control_count)

    redirect_to batch_path(@batch)
  end

  def print_labels; end

  def print_stock_labels
    @batch = Batch.find(params[:id])
  end

  def print_plate_labels
    @pipeline = @batch.pipeline
    @output_barcodes = []

    @output_assets = @batch.plate_group_barcodes || []

    @output_assets.each do |parent, _children|
      next if parent.nil?

      plate_barcode = parent.human_barcode
      @output_barcodes << plate_barcode if plate_barcode.present?
    end

    if @output_barcodes.blank?
      flash[:error] = 'Output plates do not have barcodes to print'
      redirect_to controller: 'batches', action: 'show', id: @batch.id
    end
  end

  def print_multiplex_labels
    request = @batch.requests.first
    if request.tag_number.nil?
      flash[:error] = 'No tags have been assigned.'
    elsif request.target_asset.present? && request.target_asset.children.present?
      # We are trying to find the MX library tube or the stock MX library
      # tube. I've added a filter so it doesn't pick up Lanes.
      children = request.target_asset.children.last.children.select { |a| a.is_a?(Tube) }
      @asset = if children.empty?
                 request.target_asset.children.last
               else
                 request.target_asset.children.last.children.last
               end
    else
      flash[:notice] = 'There is no multiplexed library available.'
    end
  end

  def print_stock_multiplex_labels
    @batch = Batch.find(params[:id])
    request = @batch.requests.first
    pooled_library = request.target_asset.children.first
    stock_multiplexed_tube = nil

    if pooled_library.is_a_stock_asset?
      stock_multiplexed_tube = pooled_library
    elsif pooled_library.has_stock_asset?
      stock_multiplexed_tube = pooled_library.stock_asset
    end

    if stock_multiplexed_tube.nil?
      flash[:notice] = 'There is no stock multiplexed library available.'
      redirect_to controller: 'batches', action: 'show', id: @batch.id
    else
      @asset = stock_multiplexed_tube
    end
  end

  def print_multiplex_barcodes
    print_handler(LabelPrinter::Label::BatchMultiplex)
  end

  def print_plate_barcodes
    print_handler(LabelPrinter::Label::BatchRedirect)
  end

  def print_barcodes
    if @batch.requests.empty?
      flash[:notice] = 'Your batch contains no requests.'
      redirect_to controller: 'batches', action: 'show', id: @batch.id
    else
      print_handler(LabelPrinter::Label::BatchTube)
    end
  end

  def print
    @task     = Task.find(params[:task_id]) if params[:task_id]
    @workflow = @batch.workflow
    @pipeline = @batch.pipeline
    @comments = @batch.comments

    # TODO: Re-factor this.
    if @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
      @plate = @batch.requests.first.asset.plate
    elsif @pipeline.is_a?(CherrypickingPipeline)
      @plates = if params[:barcode]
                  Plate.with_barcode(params[:barcode])
                else
                  @batch.output_plates
                end
    end

    template = @pipeline.batch_worksheet
    render action: template, layout: false
  end

  def verify
    @requests = @batch.ordered_requests
    @pipeline = @batch.pipeline
    @count = @requests.length
  end

  def verify_tube_layout
    tube_barcodes = Array.new(@batch.requests.count) { |i| params["barcode_#{i}"] }

    results = @batch.verify_tube_layout(tube_barcodes, current_user)

    if results
      flash[:notice] = 'All of the tubes are in their correct positions.'
      redirect_to batch_path(@batch)
    elsif !results
      flash[:error] = @batch.errors.full_messages.sort
      redirect_to action: :verify, id: @batch.id
    end
  end

  def reset_batch
    pipeline = @batch.pipeline
    @batch.reset!(current_user)
    flash[:notice] = "Batch #{@batch.id} has been reset"
    redirect_to controller: 'pipelines', action: :show, id: pipeline.id
  end

  def previous_qc_state
    @batch.qc_previous_state!(current_user)
    @batch.save
    flash[:notice] = "Batch #{@batch.id} reset to state #{@batch.qc_state}"
    redirect_to batch_url(@batch)
  end

  def filtered; end

  def swap
    if @batch.swap(current_user, 'batch_1' => { 'id' => params['batch']['1'], 'lane' => params['batch']['position']['1'] },
                                 'batch_2' => { 'id' => params['batch']['2'], 'lane' => params['batch']['position']['2'] })
      flash[:notice] = 'Successfully swapped lane positions'
      redirect_to batch_path(@batch)
    else
      flash[:error] = @batch.errors.full_messages.join('<br />')
      redirect_to action: :filtered, id: @batch.id
    end
  end

  def download_spreadsheet
    csv_string = Tasks::PlateTemplateHandler.generate_spreadsheet(@batch)
    send_data csv_string, type: 'text/plain',
                          filename: "#{@batch.id}_cherrypick_layout.csv",
                          disposition: 'attachment'
  end

  def gwl_file
    @plate_barcode = @batch.plate_barcode(params[:barcode])
    tecan_gwl_file_as_string = @batch.tecan_gwl_file_as_text(@plate_barcode,
                                                             @batch.total_volume_to_cherrypick,
                                                             params[:plate_type])
    send_data tecan_gwl_file_as_string, type: 'text/plain',
                                        filename: "#{@batch.id}_batch_#{@plate_barcode}.gwl",
                                        disposition: 'attachment'
  end

  def find_batch_by_id
    @batch = Batch.find(params[:id])
  end

  def find_batch_by_batch_id
    @batch = Batch.find(params[:batch_id])
  end

  def edit_volume_and_concentration
    @batch = Batch.find(params[:id])
  end

  def update_volume_and_concentration
    @batch = Batch.find(params[:batch_id])

    params[:assets].each do |id, values|
      asset = Asset.find(id)
      asset.volume = values[:volume]
      asset.concentration = values[:concentration]
      asset.save
    end

    redirect_to batch_path(@batch)
  end

  def pacbio_sample_sheet
    csv_string = PacBio::SampleSheet.new.create_csv_from_batch(@batch)
    send_data csv_string, type: 'text/plain',
                          filename: "batch_#{@batch.id}_sample_sheet.csv",
                          disposition: 'attachment'
  end

  def sample_prep_worksheet
    csv_string = PacBio::Worksheet.new.create_csv_from_batch(@batch)
    send_data csv_string, type: 'text/plain',
                          filename: "batch_#{@batch.id}_worksheet.csv",
                          disposition: 'attachment'
  end

  def find_batch_by_barcode
    batch_id = LabEvent.find_batch_id_by_barcode(params[:id])
    if batch_id.nil?
      @batch_error = 'Batch id not found.'
      render action: 'batch_error', format: :xml
      return
    else
      @batch = Batch.find(batch_id)
      render action: 'show', format: :xml
    end
  end

  private

  def print_handler(print_class)
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                           print_class,
                                           count: params[:count], printable: params[:printable], batch: @batch)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to controller: 'batches', action: 'show', id: @batch.id
  end

  def pipeline_error_on_batch_creation(message)
    respond_to do |format|
      flash[:error] = message
      format.html { redirect_to pipeline_url(@pipeline) }
    end
    nil
  end

  def transition_requests(requests, transition, message)
    ApplicationRecord.transaction { requests.each(&transition) }

    respond_to do |format|
      flash[:notice] = message
      format.html { redirect_to controller: :pipelines, action: :show, id: @pipeline.id }
      format.xml  { head :ok }
    end
  end

  # This is the expected create behaviour, and is only in a seperate
  # method due to the overloading on the create endpoint.
  def standard_create(requests)
    return pipeline_error_on_batch_creation('All plates in a submission must be selected') unless @pipeline.all_requests_from_submissions_selected?(requests)
    return pipeline_error_on_batch_creation("Maximum batch size is #{@pipeline.max_size}") if @pipeline.max_size && requests.length > @pipeline.max_size

    begin
      ActiveRecord::Base.transaction do
        @batch = @pipeline.batches.create!(requests: requests, user: current_user)
      end
    rescue ActiveRecord::RecordNotUnique => exception
      # We don't explicitly check for this on creation of batch_request for performance reasons, and the front end usually
      # ensures this situation isn't possible. However if the user opens duplicate tabs it is possible.
      # Fortunately we can detect the corresponding exception, and generate a friendly error message.

      # If this isn't the exception we're expecting, re-raise it.
      raise exception unless /request_id/.match?(exception.message)

      # Find the requests which casued the clash.
      batched_requests = BatchRequest.where(request_id: requests.map(&:id)).pluck(:request_id)
      # Limit the length of the error message, otherwise big batches may generate errors which are too
      # big to pass back in the flash.
      listed_requests = batched_requests.join(', ').truncate(200, separator: ' ')
      # And finally report the error
      return pipeline_error_on_batch_creation("Could not create batch as requests were already in a batch: #{listed_requests}")
    end

    respond_to do |format|
      format.html do
        if @pipeline.has_controls?
          flash[:notice] = 'Batch created - now add a control'
          redirect_to action: :control, id: @batch.id
        else
          redirect_to action: :show, id: @batch.id
        end
      end
      format.xml { head :created, location: batch_url(@batch) }
    end
  end
end
