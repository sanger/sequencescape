#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class BatchesController < ApplicationController
  include XmlCacheHelper::ControllerHelper

  before_filter :login_required, :except => [:released, :evaluations_counter, :qc_criteria]
  before_filter :find_batch_by_id, :only => [:show,:edit, :update, :destroy, :qc_information, :qc_batch, :save, :fail, :fail_items, :fail_batch, :assign_batch, :control, :add_control, :print_labels, :print_plate_labels, :print_multiplex_labels, :print, :verify, :verify_tube_layout, :reset_batch, :previous_qc_state, :filtered, :swap, :download_spreadsheet, :gwl_file, :pulldown_batch_report, :pacbio_sample_sheet, :sample_prep_worksheet]
  before_filter :find_batch_by_batch_id, :only => [:sort, :print_multiplex_barcodes, :print_pulldown_multiplex_tube_labels, :print_plate_barcodes, :print_barcodes]

  def index
    if logged_in?
      @user = current_user
      assigned_batches = Batch.find_all_by_assignee_id(@user.id)
      @batches = (@user.batches + assigned_batches).sort_by {|batch| batch.id}.reverse
    else
      # not reachable !!! if not login redirect to login
      @batches = Batch.find(:all)
    end
    if params[:request_id]
      @batches = [Request.find(params[:request_id]).batch].compact
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @batches.to_xml }
      format.json  { render :json => @batches.to_json.gsub(/null/, "\"\"") }
    end
  end

  def show
    @submenu_presenter = Presenters::BatchSubmenuPresenter.new(current_user, @batch)

    @pipeline = @batch.pipeline
    @tasks    = @batch.tasks.sort_by(&:sorted)
    @rits = @pipeline.request_information_types
    @input_assets, @output_assets = []
    # Should it be this?
    # @input_assets, @output_assets = [], []

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
    respond_to do |format|
      if @batch.update_attributes(params[:batch])
        flash[:notice] = 'Batch was successfully updated.'
        format.html { redirect_to batch_url(@batch) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @batch.errors.to_xml }
      end
    end
  end

  def hide_from_inbox(requests)
    ActiveRecord::Base.transaction do
      requests.map(&:hold!)
    end

    respond_to do |format|
      flash[:notice] = 'Requests hidden from inbox'
      format.html { redirect_to :controller => :pipelines, :action => :show, :id => @pipeline.id }
      format.xml  { head :ok }
    end
  end

  def cancel_requests(requests)
    ActiveRecord::Base.transaction do
      requests.map(&:cancel_before_started!)
    end

    respond_to do |format|
      flash[:notice] = 'Requests canceled'
      format.html { redirect_to :controller => :pipelines, :action => :show, :id => @pipeline.id }
      format.xml  { head :ok }
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @pipeline = Pipeline.find(params[:id])

      unless @pipeline.valid_number_of_checked_request_groups?(params)
        return pipeline_error_on_batch_creation("Too many request groups selected, maximum is #{@pipeline.max_number_of_groups}")
      end

      requests = @pipeline.extract_requests_from_input_params(params)

      return pipeline_error_on_batch_creation("Maximum batch size is #{@pipeline.max_size}") if @pipeline.max_size && requests.size > @pipeline.max_size
      return pipeline_error_on_batch_creation("All plates in a submission must be selected") unless @pipeline.all_requests_from_submissions_selected?(requests)

      return hide_from_inbox(requests) if params[:action_on_requests] == "hide_from_inbox"
      return cancel_requests(requests) if params[:action_on_requests] == "cancel_requests"

      @batch = @pipeline.batches.create!(:requests => requests, :user => current_user)

    end # of transaction

    respond_to do |format|
      format.html {
        if @pipeline.has_controls?
          flash[:notice] = 'Batch created - now add a control'
          redirect_to :action => :control, :id => @batch.id
        else
          redirect_to :action => :show, :id => @batch.id
        end
      }
      format.xml { head :created, :location => batch_url(@batch) }
    end
  rescue ActiveRecord::RecordInvalid => exception
    respond_to do |format|
      format.html {
        flash[:error] = exception.record.errors.full_messages
        redirect_to(pipeline_path(@pipeline))
      }
      format.xml  { render :xml => @batch.errors.to_xml }
    end
  end

  def pipeline
    @batches = Batch.all(:conditions => {:pipeline_id => params[:id]}, :order => "id DESC", :include => [:requests, :user, :pipeline])
  end

  # Used by Quality Control Pipeline view or remote sources to add a Batch ID to QC queue
  def start_automatic_qc
    if request.post?
      @batch = Batch.find(params[:id])

      submitted = @batch.submit_to_qc_queue

      if submitted
        @batch.lab_events.create(:description => "Submitted to QC", :message => "Batch #{@batch.id} was submitted to QC queue", :user_id => @current_user.id)
        respond_to do |format|
          message = "Batch #{@batch.id} was submitted to QC queue"
          format.html do
            flash[:info] = message
            redirect_to request.env["HTTP_REFERER"] || 'javascript:history.back()'
          end
          format.xml  { render :text => nil, :status => :success }
        end
      else
        respond_to do |format|
          message = "Batch #{@batch.id} was not submitted to QC queue!"
          format.html do
            flash[:warning] = message
            redirect_to request.env["HTTP_REFERER"] || 'javascript:history.back()'
          end
          format.xml do
            render :xml => {:error => message}.to_xml(:root => :errors), :status => :bad_request
          end
        end
      end
    else
      respond_to do |format|
        message = "There was a problem with the request. HTTP POST method was not used."
        format.html do
          flash[:error] = message
          redirect_to request.env["HTTP_REFERER"] || 'javascript:history.back()'
        end
        format.xml do
          errors = {:error => message}
          render :xml => errors.to_xml(:root => :errors), :status => :method_not_allowed
        end
      end
    end
  end

  def qc_information
    respond_to do |format|
      format.html
      format.json do
        b = @batch.formatted_batch_qc_details
        render :json => b.to_json.gsub(/null/, "\"\"")
      end
    end
  end

  # Deals with QC failures leaving batches and items statuses intact
  def qc_batch
    @batch.qc_complete

    @batch.batch_requests.each do |br|
      if br && params["#{br.request_id}"]
        qc_state = params["#{br.request_id}"]["qc_state"]
        target = br.request.target_asset
        if qc_state == "fail"
          target.set_qc_state("failed")
          EventSender.send_fail_event(br.request_id, "", "Failed manual QC", @batch.id)
        elsif qc_state == "pass"
          target.set_qc_state("passed")
          EventSender.send_pass_event(br.request_id, "", "Passed manual QC", @batch.id)
        end
        target.save
      end
    end

    @batch.release_without_user!

    redirect_to :controller => :pipelines, :action => :show, :id => @batch.qc_pipeline_id
  end

  def pending
    @pipeline = Pipeline.find(params[:id])
    @batches = @pipeline.batches.pending.all(:order => "id DESC", :include => [:requests, :user, :pipeline])
  end

  def started
    @pipeline = Pipeline.find(params[:id])
    @batches = @pipeline.batches.started.all(:order => "id DESC", :include => [:requests, :user, :pipeline])
  end

  def released
    @pipeline = Pipeline.find(params[:id])

    @batches = @pipeline.batches.released.all(:order => "id DESC", :include => [:user ])
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end

  def completed
    @pipeline = Pipeline.find(params[:id])
    @batches = @pipeline.batches.completed.all(:order => "id DESC", :include => [:requests, :user, :pipeline])
  end

  def failed
    @pipeline = Pipeline.find(params[:id])
    @batches = @pipeline.batches.failed.all(:order => "id DESC", :include => [:requests, :user, :pipeline])
  end

  def fail
    if @batch.workflow.source_is_internal?
      @fail_reasons = FAILURE_REASONS["internal"]
    else
      @fail_reasons = FAILURE_REASONS["external"]
    end
  end

  def quality_control
    @qc_pipeline = Pipeline.find(params[:id])
    conditions_query = []
    if params["state"]
      conditions_query = ["state = ? AND qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", params["state"], params["qc_state"], @qc_pipeline.id, @qc_pipeline.cluster_formation_pipeline_id]
    else
      conditions_query = ["qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", params["qc_state"], @qc_pipeline.id, @qc_pipeline.cluster_formation_pipeline_id]
    end

    @batches = Batch.find(:all, :conditions => conditions_query, :include => [:user], :order => "created_at ASC")
  end

  def fail_items
    ActiveRecord::Base.transaction do
      unless params[:failure][:reason].empty?
        reason = params[:failure][:reason]
        comment = params[:failure][:comment]
        requests = params[:requested_fail] || {}
        fail_but_charge = params[:failure][:fail_but_charge]=='1'
        requests_for_removal = params[:requested_remove] || {}
        # Check to see if the user is trying to remove AND fail the same request.
        diff = requests_for_removal.keys & requests.keys

        unless diff.empty?
          flash[:error] = "Fail and remove were both selected for the following - #{diff.to_sentence} this is not supported."
        else
          if requests.empty? && requests_for_removal.empty?
            flash[:error] = "Please select an item to fail or remove"
          else
            unless requests.empty?
              @batch.fail_batch_items(requests, reason, comment, fail_but_charge)
              flash[:notice] = "#{requests.keys.to_sentence} set to failed.#{fail_but_charge ? ' The customer will still be charged.':''}"
            end

            unless requests_for_removal.empty?
              @batch.remove_request_ids(requests_for_removal.keys, reason, comment)
              flash[:notice] = "#{requests_for_removal.keys.to_sentence} removed."
            end
          end
        end
        redirect_to :action => "fail", :id => @batch.id
      else
        flash[:error] = "Please specify a failure reason for this batch"
        redirect_to :action => :fail, :id => @batch.id
      end
    end
  end

  def sort
    @batch.assign_positions_to_requests!(params['requests_list'].map(&:to_i))
    render :nothing => true
  end

  def save
    redirect_to :action => :show, :id => @batch.id
  end

  def assign_batch
    @user = User.find(params[:assignee][:id])
    @batch.assignee_id = @user.id
    if @batch.save
      flash[:notice] = "Batch assigned to #{@user.login}"
      redirect_to :action => "edit", :id => @batch.id
    else
      flash[:notice] = "Could not assign batch"
      redirect_to :action => "edit", :id => @batch.id
    end
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
      redirect_to :action => "control", :id => @batch.id
      return
    elsif control_count < 0
      flash[:error] = "This batch needs at least one control"
      redirect_to :action => "control", :id => @batch.id
      return
    end
    control_count = @batch.add_control(@control.name, control_count)

    redirect_to batch_path(@batch)
  end

  def create_training_batch
    control = Control.find(params[:control][:id])
    pipeline = control.pipeline
    limit = pipeline.item_limit

    batch = pipeline.batches.create!(:item_limit => limit, :user_id => current_user.id)
    batch.add_control(control.name, pipeline.item_limit)

    flash[:notice] = 'Training batch created'
    redirect_to :action => "show", :id => batch.id
  end

  def evaluations_counter
    @ev = BatchStatus.find(params[:id])
    render :partial => 'evaluations_counter'
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

    @output_assets.each do |parent, children|
      unless parent.nil?
        plate_barcode = parent.barcode
        unless plate_barcode.blank?
          @output_barcodes << plate_barcode
        end
      end
    end

    if @output_barcodes.blank?
      flash[:error] = "Output plates do not have barcodes to print"
      redirect_to :controller => 'batches', :action => 'show', :id => @batch.id
    else
    end
  end

  def print_multiplex_labels
    request = @batch.requests.first
    unless request.tag_number.nil?
      if ! request.target_asset.nil? && ! request.target_asset.children.empty?
        # We are trying to find the MX library tube or the stock MX library
        # tube. I've added a filter so it doesn't pick up Lanes.
        children = request.target_asset.children.last.children.select { |a| a.is_a?(Tube) }
        if children.empty?
          @asset = request.target_asset.children.last
        else
          @asset = request.target_asset.children.last.children.last
        end
      else
        flash[:notice] = "There is no multiplexed library available."
      end
    else
      flash[:error] = "No tags have been assigned."
    end
    # @assets = @batch.multiplexed_items_with_unique_library_ids
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
      flash[:notice] = "There is no stock multiplexed library available."
      redirect_to :controller => 'batches', :action => 'show', :id => @batch.id
    else
      @asset = stock_multiplexed_tube
    end
  end

  def print_multiplex_barcodes
    printables = []
    count = params[:count].to_i

    params[:printable].each do |key, value|
      if value == 'on'
        asset = Asset.find(key)
        if @batch.multiplexed?
          count.times do
            printables.push PrintBarcode::Label.new({ :number => asset.barcode, :study => "(p) #{asset.name}" })
          end
        end
      end
    end

    unless printables.empty?
      asset = @batch.assets.first
      begin
        printables.sort! {|a,b| a.number <=> b.number }
        BarcodePrinter.print(printables, params[:printer], asset.prefix, "short")
      rescue PrintBarcode::BarcodeException
        flash[:error] = "Label printing to #{params[:printer]} failed: #{$!}."
      rescue Savon::Error
        flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
      else
        flash[:notice] = "Your labels have been printed to #{params[:printer]}."
      end
    end
    redirect_to :controller => 'batches', :action => 'show', :id => @batch.id
  end

  def print_plate_barcodes
    printables = []
    count = params[:count].to_i
    params[:printable].each do |key, value|
      if value == 'on'
        label = key
        identifier = key
        count.times do
          printables.push PrintBarcode::Label.new({ :number => identifier, :study => label, :batch => @batch })
        end
      end
    end
    unless printables.empty?
      begin
        printables.sort! {|a,b| a.number <=> b.number }
        BarcodePrinter.print(printables, params[:printer], "DN", "cherrypick",@batch.study.abbreviation, current_user.login)
      rescue PrintBarcode::BarcodeException
        flash[:error] = "Label printing to #{params[:printer]} failed: #{$!}."
      rescue Savon::Error
        flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
      else
        flash[:notice] = "Your labels have been printed to #{params[:printer]}."
      end
    end
    redirect_to :controller => 'batches', :action => 'show', :id => @batch.id
  end


  def print_barcodes
    unless @batch.requests.empty?
      asset = @batch.requests.first.target_asset
      printables = []
      count = params[:count].to_i
      params[:printable].each do |key, value|
        if value == 'on'
          request = Request.find(key)
          if params[:stock]
            if @batch.multiplexed?
              stock = request.target_asset.children.first
              identifier = stock.barcode
              label = stock.name
            else
              stock = request.target_asset.stock_asset
              identifier = stock.barcode
              label = stock.name
            end
          else
            if @batch.multiplexed?
              unless request.tag_number.nil?
                label = "(#{request.tag_number}) #{request.target_asset.id}"
                identifier = request.target_asset.barcode
              else
                label = request.target_asset.name
                identifier = request.target_asset.barcode
              end
            else
              label = request.target_asset.tube_name
              identifier = request.target_asset.barcode
            end
          end
          count.times do
            printables.push PrintBarcode::Label.new({ :number => identifier, :study => label })
          end
        end
      end
      unless printables.empty?
        begin
          printables.sort! {|a,b| b.number <=> a.number }
          BarcodePrinter.print(printables, params[:printer], asset.prefix, "short")
        rescue PrintBarcode::BarcodeException
          flash[:error] = "Label printing to #{params[:printer]} failed: #{$!}."
        rescue Savon::Error
          flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
        else
          flash[:notice] = "Your labels have been printed to #{params[:printer]}."
        end
      end
    else
      flash[:notice] = "Your batch contains no requests."
    end
    redirect_to :controller => 'batches', :action => 'show', :id => @batch.id
  end

  def print
    if params[:task_id]
      @task = Task.find(params[:task_id])
    end

    @workflow = @batch.workflow
    @pipeline = @batch.pipeline
    @comments = @batch.comments

    # TODO: Re-factor this.

    if @pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline)
      @plate = @batch.requests.first.asset.plate
      render :action => "pulldown_worksheet", :layout => false
    elsif @pipeline.is_a?(CherrypickingPipeline)
      if params[:barcode]
        @plates = [Plate.find_by_barcode(params[:barcode])]
      else
        @plates = @batch.output_plates
      end
      render :action => "cherrypick_worksheet", :layout => false
    elsif @batch.has_item_limit?
      # Currently cluster formation pipelines
      render :action => "simplified_worksheet", :layout => false
    elsif @batch.multiplexed?
      if @task
        render :action => "multiplexed_library_worksheet", :layout => false, :locals => {:task => @task}
      else
        render :action => "multiplexed_library_worksheet", :layout => false
      end
    else
      if @task
        render :action => "detailed_worksheet", :layout => false, :locals => {:task => @task}
      else
        render :action => "detailed_worksheet", :layout => false
      end
    end
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
          tube_barcodes["#{i + 1}"] = Barcode.split_barcode("#{params["barcode_#{i}"]}")[1]
        end
      end
    end
    results = @batch.verify_tube_layout(tube_barcodes, current_user)

    if results
      flash[:notice] = "All of the tubes are in their correct positions."
      redirect_to batch_path(@batch)
    elsif ! results
      flash[:error] = @batch.errors.full_messages.sort
      redirect_to :action => :verify, :id => @batch.id
    end
  end

  def reset_batch
    pipeline = @batch.pipeline
    @batch.reset!(current_user)
    flash[:notice] = "Batch #{@batch.id} has been reset"
    redirect_to :controller => "pipelines", :action => :show, :id => pipeline.id
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
    if @batch.swap(current_user, {"batch_1" => {"id"=>params["batch"]["1"], "lane"=>params["batch"]["position"]["1"]},
                    "batch_2" => {"id"=>params["batch"]["2"], "lane"=>params["batch"]["position"]["2"]}
                  })
      flash[:notice] = "Successfully swapped lane positions"
      redirect_to batch_path(@batch)
    else
      flash[:error] = @batch.errors.full_messages.join("<br />")
      redirect_to :action => :filtered, :id => @batch.id
    end
  end

  def download_spreadsheet
    csv_string = Tasks::PlateTemplateHandler.generate_spreadsheet(@batch)
    send_data csv_string, :type => "text/plain",
     :filename=>"#{@batch.id}_cherrypick_layout.csv",
     :disposition => 'attachment'
  end

  def gwl_file
    @plate_barcode = @batch.plate_barcode(params[:barcode])
    tecan_gwl_file_as_string = @batch.tecan_gwl_file_as_text(@plate_barcode,
                                                             @batch.total_volume_to_cherrypick,
                                                             params[:plate_type])
    send_data tecan_gwl_file_as_string, :type => "text/plain",
     :filename=>"#{@batch.id}_batch_#{@plate_barcode}.gwl",
     :disposition => 'attachment'
  end

  def find_batch_by_id
    @batch = Batch.find(params[:id])
  end

  def find_batch_by_batch_id
    @batch = Batch.find(params[:batch_id])
  end

  def new_stock_assets
    @batch = Batch.find(params[:id])
    unless @batch.requests.empty?
      @batch_assets = []
      unless @batch.multiplexed?
        @batch_assets = @batch.requests.map(&:target_asset)
        @batch_assets.delete_if{ |a| a.has_stock_asset? }
        if @batch_assets.empty?
          flash[:error] = "Stock tubes already exist for everything."
          redirect_to batch_path(@batch)
        end
      else
        unless @batch.requests.first.target_asset.children.empty?
          multiplexed_library = @batch.requests.first.target_asset.children.first

          if  ! multiplexed_library.has_stock_asset? && ! multiplexed_library.is_a_stock_asset?
            @batch_assets = [multiplexed_library]
          else
            flash[:error] = "Already has a Stock tube."
            redirect_to batch_path(@batch)
          end
        else
          flash[:error] = "There's no multiplexed library tube available to have a stock tube."
          redirect_to batch_path(@batch)
        end
      end
      @assets = {}
      @batch_assets.each do |batch_asset|
        @assets[batch_asset.id] = batch_asset.new_stock_asset
      end
    end
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

  def pulldown_batch_report
    csv_string = @batch.pulldown_batch_report
    send_data csv_string, :type => "text/plain",
     :filename=>"batch_#{@batch.id}_report.csv",
     :disposition => 'attachment'

  end

  def pacbio_sample_sheet
    csv_string = PacBio::SampleSheet.new.create_csv_from_batch(@batch)
    send_data csv_string, :type => "text/plain",
     :filename=>"batch_#{@batch.id}_sample_sheet.csv",
     :disposition => 'attachment'
  end

  def sample_prep_worksheet
    csv_string = PacBio::Worksheet.new.create_csv_from_batch(@batch)
    send_data csv_string, :type => "text/plain",
     :filename=>"batch_#{@batch.id}_worksheet.csv",
     :disposition => 'attachment'
  end


  def find_batch_by_barcode
    batch_id = LabEvent.find_by_barcode(params[:id])
    if batch_id == 0
      @batch_error = "Batch id not found."
      render :action => "batch_error", :format => :xml
      return
    else
      @batch = Batch.find(batch_id)
      render :action => "show", :format => :xml
    end
  end

  private
  def pipeline_error_on_batch_creation(message)
    respond_to do |format|
      flash[:error] = message
      format.html { redirect_to pipeline_url(@pipeline) }
    end
    return
  end

end
