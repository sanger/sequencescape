# frozen_string_literal: true

# Batches represent collections of {Request requests} processed through a {Pipeline}
# at the same time. They are created via selecting requests on the {PipelinesController#show pipelines show page}
class BatchesController < ApplicationController # rubocop:todo Metrics/ClassLength
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behaviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.

  before_action :evil_parameter_hack!

  before_action :login_required, except: %i[released]
  before_action :find_batch_by_id,
                only: %i[
                  show
                  edit
                  update
                  save
                  fail
                  print_labels
                  print_plate_labels
                  print
                  verify
                  verify_tube_layout
                  reset_batch
                  previous_qc_state
                  filtered
                  swap
                  download_spreadsheet
                ]
  before_action :find_batch_by_batch_id, only: %i[sort print_plate_barcodes print_barcodes]

  def index # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    if logged_in?
      @user = params.fetch(:user, current_user)
      @batches = Batch.for_user(@user).order(id: :desc).includes(:user, :assignee, :pipeline).page(params[:page])
    else
      # Can end up here with XML. And it causes pain.
      @batches = Batch.order(id: :asc).page(params[:page]).limit(10)
    end
    respond_to do |format|
      format.html
      format.xml { render xml: @batches.to_xml }
      format.json { render json: @batches.to_json.gsub('null', '""') }
    end
  end

  # rubocop:todo Metrics/MethodLength
  def show # rubocop:todo Metrics/AbcSize
    respond_to do |format|
      format.html do
        @submenu_presenter = Presenters::BatchSubmenuPresenter.new(current_user, @batch)

        @pipeline = @batch.pipeline
        @tasks = @batch.tasks.sort_by(&:sorted)
        @rits = @pipeline.request_information_types
        @input_labware = @batch.input_labware_report
        @output_labware = @batch.output_labware_report

        if @pipeline.pick_data
          @robot = @batch.robot_id ? Robot.find(@batch.robot_id) : Robot.with_verification_behaviour.first

          # In the event we have no robots with the correct behaviour, and none are specialised on the batch, fall-back
          # to the first robot.
          @robot ||= Robot.first
          @robots = Robot.with_verification_behaviour
        end
      end
      format.xml { render layout: false }
    end
  end

  # rubocop:enable Metrics/MethodLength

  def edit
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests.includes(:batch_request, :asset, :target_asset, :comments)
    @users = User.all
    @controls = @batch.pipeline.controls
  end

  # rubocop:todo Metrics/MethodLength
  def create # rubocop:todo Metrics/AbcSize
    @pipeline = Pipeline.find(params[:id])

    requests = @pipeline.extract_requests_from_input_params(request_parameters)

    # TODO: These should be different endpoints
    case params[:action_on_requests]
    when 'cancel_requests'
      transition_requests(requests, :cancel_before_started!, 'Requests cancelled')
    when 'hide_from_inbox'
      transition_requests(requests, :hold!, 'Requests hidden from inbox')
    else
      # This is the standard create action
      standard_create(requests)
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html do
        flash[:error] = e.record.errors.full_messages
        redirect_to(pipeline_path(@pipeline))
      end
      format.xml { render xml: @batch.errors.to_xml }
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def update # rubocop:todo Metrics/AbcSize
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
        format.xml { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @batch.errors.to_xml }
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  def batch_parameters
    @batch_parameters ||= params.require(:batch).permit(:assignee_id)
  end

  def pipeline
    # All pipeline batches routes should just direct to batches#index with pipeline and state as filter parameters
    @batches =
      Batch
        .where(pipeline_id: params[:pipeline_id] || params[:id])
        .order(id: :desc)
        .includes(:user, :pipeline)
        .page(params[:page])
  end

  def pending
    # The params fall-back here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.pending.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def started
    # The params fall-back here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.started.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def released
    # The params fall-back here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])

    @batches = @pipeline.batches.released.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
    respond_to do |format|
      format.html
      format.xml { render layout: false }
    end
  end

  def completed
    # The params fall-back here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.completed.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def failed
    # The params fall-back here reflects an older route where pipeline got passed in as :id. It should be removed
    # in the near future.
    @pipeline = Pipeline.find(params[:pipeline_id] || params[:id])
    @batches = @pipeline.batches.failed.order(id: :desc).includes(%i[user pipeline]).page(params[:page])
  end

  def fail
    @fail_reasons = @batch.workflow.source_is_internal? ? FAILURE_REASONS['internal'] : FAILURE_REASONS['external']
  end

  def fail_items # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    ActiveRecord::Base.transaction do
      fail_params =
        params.permit(:id, requested_fail: {}, requested_remove: {}, failure: %i[reason comment fail_but_charge])
      fail_and_remover = Batch::RequestFailAndRemover.new(fail_params)
      if fail_and_remover.save
        flash[:notice] = truncate_flash(fail_and_remover.notice)
      else
        flash[:error] = truncate_flash(fail_and_remover.errors.full_messages.join(';'))
      end
      redirect_to action: :fail, id: params[:id]
    end
  end

  def sort
    @batch.assign_positions_to_requests!(params['requests_list'].map(&:to_i))

    # Touch the batch to update its timestamp and trigger re-broadcast
    @batch.touch # rubocop:disable Rails/SkipsModelValidations
    head :ok
  end

  def save
    redirect_to action: :show, id: @batch.id
  end

  def print_labels; end

  def print_plate_labels # rubocop:todo Metrics/MethodLength
    @pipeline = @batch.pipeline
    @output_barcodes = []

    @output_labware = @batch.plate_group_barcodes || []

    @output_labware.each_key do |parent|
      next if parent.nil?

      plate_barcode = parent.human_barcode
      @output_barcodes << plate_barcode if plate_barcode.present?
    end

    return if @output_barcodes.present?

    # We have no output barcodes, which means a problem
    flash[:error] = 'Output plates do not have barcodes to print'
    redirect_to controller: 'batches', action: 'show', id: @batch.id
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

  # Handles printing of the worksheet
  def print # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @task = Task.find_by(id: params[:task_id])
    @pipeline = @batch.pipeline
    @comments = @batch.comments
    template = @pipeline.batch_worksheet

    if template == 'cherrypick_worksheet'
      robot_id = params.fetch(:robot_id, @batch.robot_id)
      @robot = robot_id ? Robot.find(robot_id) : Robot.default_for_verification
      @plates = params[:barcode] ? Plate.with_barcode(params[:barcode]) : @batch.output_plates
    end

    if template
      render action: template, layout: false
    else
      redirect_back fallback_location: batch_path(@batch), alert: "No worksheet for #{@pipeline.name}"
    end
  end

  def verify
    @requests = @batch.ordered_requests
    @pipeline = @batch.pipeline
    @count = @requests.length
  end

  def verify_tube_layout # rubocop:todo Metrics/AbcSize
    tube_barcodes = Array.new(@batch.requests.count) { |i| params["barcode_#{i}"] }

    if @batch.verify_tube_layout(tube_barcodes, current_user)
      flash[:notice] = 'All of the tubes are in their correct positions.'
      redirect_to batch_path(@batch)
    else
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

  def swap # rubocop:todo Metrics/AbcSize
    if @batch.swap(
         current_user,
         'batch_1' => {
           'id' => params['batch']['1'],
           'lane' => params['batch']['position']['1']
         },
         'batch_2' => {
           'id' => params['batch']['2'],
           'lane' => params['batch']['position']['2']
         }
       )
      flash[:notice] = 'Successfully swapped lane positions'
      redirect_to batch_path(@batch)
    else
      flash[:error] = @batch.errors.full_messages.join('<br />')
      redirect_to action: :filtered, id: @batch.id
    end
  end

  # Used in Cherrypicking pipeline to generate the template for CSV driven picks
  def download_spreadsheet
    csv_string = Tasks::PlateTemplateHandler.generate_spreadsheet(@batch)
    send_data csv_string, type: 'text/plain', filename: "#{@batch.id}_cherrypick_layout.csv", disposition: 'attachment'
  end

  def find_batch_by_id
    @batch = Batch.find(params[:id])
  end

  def find_batch_by_batch_id
    @batch = Batch.find(params[:batch_id])
  end

  def find_batch_by_barcode
    batch_id = LabEvent.find_batch_id_by_barcode(params[:id])
    if batch_id.nil?
      @batch_error = 'Batch id not found.'
      render action: 'batch_error', format: :xml
      nil
    else
      @batch = Batch.find(batch_id)
      render action: 'show', format: :xml
    end
  end

  private

  def print_handler(print_class) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    print_job =
      LabelPrinter::PrintJob.new(
        params[:printer],
        print_class,
        count: params[:count],
        printable: params[:printable],
        batch: @batch
      )
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to controller: 'batches', action: 'show', id: @batch.id
  end

  def pipeline_error_on_batch_creation(message)
    respond_to do |format|
      flash[:error] = truncate_flash(message)
      format.html { redirect_to pipeline_url(@pipeline) }
    end
    nil
  end

  def transition_requests(requests, transition, message)
    ApplicationRecord.transaction { requests.each(&transition) }

    respond_to do |format|
      flash[:notice] = message
      format.html { redirect_to controller: :pipelines, action: :show, id: @pipeline.id }
      format.xml { head :ok }
    end
  end

  # This is the expected create behaviour, and is only in a separate
  # method due to the overloading on the create endpoint.
  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def standard_create(requests) # rubocop:todo Metrics/CyclomaticComplexity
    unless @pipeline.all_requests_from_submissions_selected?(requests)
      return pipeline_error_on_batch_creation('All plates in a submission must be selected')
    end
    if @pipeline.max_size && requests.length > @pipeline.max_size
      return pipeline_error_on_batch_creation("Maximum batch size is #{@pipeline.max_size}")
    end
    return pipeline_error_on_batch_creation('Batches must contain at least one request') if requests.empty?

    begin
      ActiveRecord::Base.transaction { @batch = @pipeline.batches.create!(requests:, user: current_user) }
    rescue ActiveRecord::RecordNotUnique => e
      # We don't explicitly check for this on creation of batch_request for performance reasons, and the front end
      # usually ensures this situation isn't possible. However if the user opens duplicate tabs it is possible.
      # Fortunately we can detect the corresponding exception, and generate a friendly error message.

      # If this isn't the exception we're expecting, re-raise it.
      raise e unless e.message.include?('request_id')

      # Find the requests which caused the clash.
      batched_requests = BatchRequest.where(request_id: requests.map(&:id)).pluck(:request_id)

      # And finally report the error
      return(
        pipeline_error_on_batch_creation(
          "Could not create batch as requests were already in a batch: #{batched_requests.to_sentence}"
        )
      )
    end

    respond_to do |format|
      format.html { redirect_to action: :show, id: @batch.id }
      format.xml { head :created, location: batch_url(@batch) }
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def request_parameters
    params.permit(request: {}, request_group: {}).to_h
  end
end
