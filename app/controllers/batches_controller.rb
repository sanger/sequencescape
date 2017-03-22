# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class BatchesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.

  before_action :evil_parameter_hack!
  include XmlCacheHelper::ControllerHelper

  before_action :login_required, except: [:released, :qc_criteria]
  before_action :find_batch_by_id, only: [
    :show, :edit, :update, :qc_information, :qc_batch, :save, :fail, :fail_items,
    :fail_batch, :control, :add_control, :print_labels, :print_plate_labels, :print_multiplex_labels,
    :print, :verify, :verify_tube_layout, :reset_batch, :previous_qc_state, :filtered, :swap,
    :download_spreadsheet, :gwl_file, :pacbio_sample_sheet, :sample_prep_worksheet
  ]
  before_action :find_batch_by_batch_id, only: [:sort, :print_multiplex_barcodes, :print_pulldown_multiplex_tube_labels, :print_plate_barcodes, :print_barcodes]

  def index
    if logged_in?
      @user = current_user
      @batches = Batch.where('assignee_id = :user OR user_id = :user', user: @user).order(id: :desc).page(params[:page])
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
    @submenu_presenter = Presenters::BatchSubmenuPresenter.new(current_user, @batch)

    @pipeline = @batch.pipeline
    @tasks    = @batch.tasks.sort_by(&:sorted)
    @rits = @pipeline.request_information_types
    @input_assets, @output_assets = [], []

    if @pipeline.group_by_parent
      @input_assets = @batch.input_group
      @output_assets = @batch.output_group_by_holder unless @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
    end

    respond_to do |format|
      format.html
      format.xml { cache_xml_response(@batch) }
    end
  end

  def edit
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
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
      requests = @pipeline.extract_requests_from_input_params(params)

      case params[:action_on_requests]
      when 'cancel_requests'
        return cancel_requests(requests)
      when 'hide_from_inbox'
        return hide_from_inbox(requests)
      else
        # This is the standard create action
        standard_create(requests)
      end
  rescue ActiveRecord::RecordInvalid => exception
    respond_to do |format|
      format.html {
        flash[:error] = exception.record.errors.full_messages
        redirect_to(pipeline_path(@pipeline))
      }
      format.xml { render xml: @batch.errors.to_xml }
    end
  end

  def pipeline
    # All pipline batches routes should just direct to batches#index with pipeline and state as filter parameters
    @batches = Batch.where(pipeline_id: params[:pipeline_id] || params[:id]).order(id: :desc).includes(:user, :pipeline).page(params[:page])
  end

  def qc_information
    respond_to do |format|
      format.html
      format.json do
        b = @batch.formatted_batch_qc_details
        render json: b.to_json.gsub(/null/, '""')
      end
    end
  end

  # Deals with QC failures leaving batches and items statuses intact
  def qc_batch
    @batch.qc_complete

    @batch.batch_requests.each do |br|
      if br && params[(br.request_id).to_s]
        qc_state = params[(br.request_id).to_s]['qc_state']
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
    end

    @batch.release_without_user!

    redirect_to controller: :pipelines, action: :show, id: @batch.qc_pipeline_id
  end

  def pending
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.pending.order(id: :desc).includes([:user, :pipeline]).page(params[:page])
  end

  def started
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.started.order(id: :desc).includes([:user, :pipeline]).page(params[:page])
  end

  def released
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])

    @batches = @pipeline.batches.released.order(id: :desc).includes([:user, :pipeline]).page(params[:page])
    respond_to do |format|
      format.html
      format.xml { render layout: false }
    end
  end

  def completed
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.completed.order(id: :desc).includes([:user, :pipeline]).page(params[:page])
  end

  def failed
    # The params fallback here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.failed.order(id: :desc).includes([:user, :pipeline]).page(params[:page])
  end

  def fail
    if @batch.workflow.source_is_internal?
      @fail_reasons = FAILURE_REASONS['internal']
    else
      @fail_reasons = FAILURE_REASONS['external']
    end
  end

  def fail_items
    ActiveRecord::Base.transaction do
      if params[:failure][:reason].empty?
        flash[:error] = 'Please specify a failure reason for this batch'
        redirect_to action: :fail, id: @batch.id
      else
        reason = params[:failure][:reason]
        comment = params[:failure][:comment]
        requests = params[:requested_fail] || {}
        fail_but_charge = params[:failure][:fail_but_charge] == '1'
        requests_for_removal = params[:requested_remove] || {}
        # Check to see if the user is trying to remove AND fail the same request.
        diff = requests_for_removal.keys & requests.keys

        if diff.empty?
          if requests.empty? && requests_for_removal.empty?
            flash[:error] = 'Please select an item to fail or remove'
          else
            unless requests.empty?
              @batch.fail_batch_items(requests, reason, comment, fail_but_charge)
              flash[:notice] = "#{requests.keys.to_sentence} set to failed.#{fail_but_charge ? ' The customer will still be charged.' : ''}"
            end

            unless requests_for_removal.empty?
              @batch.remove_request_ids(requests_for_removal.keys, reason, comment)
              flash[:notice] = "#{requests_for_removal.keys.to_sentence} removed."
            end
          end
        else
          flash[:error] = "Fail and remove were both selected for the following - #{diff.to_sentence} this is not supported."
        end
        redirect_to action: 'fail', id: @batch.id
      end
    end
  end

  def sort
    @batch.assign_positions_to_requests!(params['requests_list'].map(&:to_i))
    render nothing: true
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

  def create_training_batch
    control = Control.find(params[:control][:id])
    pipeline = control.pipeline
    limit = pipeline.item_limit

    batch = pipeline.batches.create!(item_limit: limit, user_id: current_user.id)
    batch.add_control(control.name, pipeline.item_limit)

    flash[:notice] = 'Training batch created'
    redirect_to action: 'show', id: batch.id
  end

  def print_labels
  end

  def print_stock_labels
    @batch = Batch.find(params[:id])
  end

  def print_plate_labels
    @pipeline = @batch.pipeline
    @output_barcodes = []

    @output_assets = @batch.plate_group_barcodes || []

    @output_assets.each do |parent, _children|
      unless parent.nil?
        plate_barcode = parent.barcode
        unless plate_barcode.blank?
          @output_barcodes << plate_barcode
        end
      end
    end

    if @output_barcodes.blank?
      flash[:error] = 'Output plates do not have barcodes to print'
      redirect_to controller: 'batches', action: 'show', id: @batch.id
    else
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
      if children.empty?
        @asset = request.target_asset.children.last
      else
        @asset = request.target_asset.children.last.children.last
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
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                        LabelPrinter::Label::BatchMultiplex,
                                        count: params[:count], printable: params[:printable], batch: @batch)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to controller: 'batches', action: 'show', id: @batch.id
  end

  def print_plate_barcodes
    print_job = LabelPrinter::PrintJob.new(params[:printer],
                                           LabelPrinter::Label::BatchPlate,
                                           count: params[:count], printable: params[:printable], batch: @batch)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to controller: 'batches', action: 'show', id: @batch.id
  end

  def print_barcodes
    if @batch.requests.empty?
      flash[:notice] = 'Your batch contains no requests.'
    else
      print_job = LabelPrinter::PrintJob.new(params[:printer],
                                          LabelPrinter::Label::BatchTube,
                                          stock: params[:stock], count: params[:count], printable: params[:printable], batch: @batch)
      if print_job.execute
        flash[:notice] = print_job.success
      else
        flash[:error] = print_job.errors.full_messages.join('; ')
      end

    end
    redirect_to controller: 'batches', action: 'show', id: @batch.id
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
                  [Plate.find_by(barcode: params[:barcode])]
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
    @count = 8
  end

  def verify_tube_layout
    tube_barcodes = {}
    unless params.empty?
      8.times do |i|
        if params["barcode_#{i}"]
          tube_barcodes[(i + 1).to_s] = Barcode.split_barcode((params["barcode_#{i}"]).to_s)[1]
        end
      end
    end
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

  def filtered
  end

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

  def pipeline_error_on_batch_creation(message)
    respond_to do |format|
      flash[:error] = message
      format.html { redirect_to pipeline_url(@pipeline) }
    end
    nil
  end

  def hide_from_inbox(requests)
    ActiveRecord::Base.transaction do
      requests.map(&:hold!)
    end

    respond_to do |format|
      flash[:notice] = 'Requests hidden from inbox'
      format.html { redirect_to controller: :pipelines, action: :show, id: @pipeline.id }
      format.xml  { head :ok }
    end
  end

  def cancel_requests(requests)
    ActiveRecord::Base.transaction do
      requests.map(&:cancel_before_started!)
    end

    respond_to do |format|
      flash[:notice] = 'Requests canceled'
      format.html { redirect_to controller: :pipelines, action: :show, id: @pipeline.id }
      format.xml  { head :ok }
    end
  end

  # This is the expected create behaviour, and is only in a seperate
  # method due to the overloading on the create endpoint.
  def standard_create(requests)
    ActiveRecord::Base.transaction do
      unless @pipeline.valid_number_of_checked_request_groups?(params)
        return pipeline_error_on_batch_creation("Too many request groups selected, maximum is #{@pipeline.max_number_of_groups}")
      end
      return pipeline_error_on_batch_creation('All plates in a submission must be selected') unless @pipeline.all_requests_from_submissions_selected?(requests)
      return pipeline_error_on_batch_creation("Maximum batch size is #{@pipeline.max_size}") if @pipeline.max_size && requests.length > @pipeline.max_size
      @batch = @pipeline.batches.create!(requests: requests, user: current_user)
    end

    respond_to do |format|
      format.html {
        if @pipeline.has_controls?
          flash[:notice] = 'Batch created - now add a control'
          redirect_to action: :control, id: @batch.id
        else
          redirect_to action: :show, id: @batch.id
        end
      }
      format.xml { head :created, location: batch_url(@batch) }
    end
  end
end
