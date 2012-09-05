class RequestsController < ApplicationController

  before_filter :admin_login_required, :only => [ :describe, :undescribe, :destroy ]
 # before_filter :find_request_from_id, :only => [ :filter_change_decision, :change_decision ]

  def index
    @no_filter_params, @study, @item, query_options = true, nil, nil, { :order => 'created_at DESC' }

    # Ok, here we pick the initial source for the Requests.  They either come from Request (as in all Requests), or they
    # are limited by the Asset / Item.
    request_source = Request
    if params[:item_id]
      @no_filter_params = false
      @item             = Item.find(params[:item_id])
      request_source    = @item.requests
    elsif params[:asset_id]
      @no_filter_params = false
      @item             = Asset.find(params[:asset_id])
      request_source    = @item.requests
    end

    # Now we can change the source for the Requests based on filtering parameters.
    if params[:request_type_id]
      @no_filter_params = false
      @request_type     = RequestType.find(params[:request_type_id])
      request_source    = request_source.request_type(params[:request_type_id])
    elsif params[:request_type] and params[:workflow]
      @no_filter_params = false
      request_source    = request_source.for_request_types(params[:request_type]).for_workflow(params[:workflow])
      query_options[ :include ] = :user
    end
    if params[:study_id]
      @no_filter_params = false
      @study            = Study.find(params[:study_id])
      request_source    = request_source.for_initial_study_id(params[:study_id])
    end
    if params[:state]
      @no_filter_params = false
      request_source    = request_source.for_state(params[:state])
    end

    # Now, here we go: find all of the requests!
    @requests =
      if @no_filter_params
        Request.paginate(:page => params[:page], :order => 'created_at DESC')
      else
        request_source.all(query_options)
      end

    respond_to do |format|
      format.html
      format.xml { render :xml => Request.all.to_xml }
    end
  end

  def edit
    @request = Request.find(params[:id])
    @request_types = RequestType.find_all_by_asset_type(@request.request_type.asset_type)
    if current_user.is_administrator?
      respond_to do |format|
        format.html
      end
    else
      flash[:error] = "You cannot update a request unless you're an administrator"
      redirect_to request_path(@request)
    end
  end

  def update
    @request = Request.find(params[:id])
    if redirect_if_not_owner_or_admin
      return
    end

    if params[:request][:state] == "cancelled" && !@request.cancelable?
      flash[:notice] = "You can not cancel a request that is in progress."
      redirect_to request_path(@request)
      return
    end

    unless params[:request][:request_type_id].nil?
      unless @request.request_type_updatable?(params[:request][:request_type_id])
        flash[:error] = "You can not change the request type. Insufficient quota for #{RequestType.find(params[:request][:request_type_id]).name.downcase}."
        redirect_to request_path(@request)
        return
      end
   end

    parameters = params[:request]
#    parameters[:properties] = params[:request][:properties] if params[:request][:properties]
    begin
      if @request.update_attributes(parameters)
        flash[:notice] = "Request details have been updated"
        if params[:request][:state] == "failed"
          flash[:notice] = "Request #{params[:id]} has been failed"
          EventFactory.request_update_note_to_manager(@request, current_user, flash[:notice])
        end
        redirect_to request_path(@request)
      else
        flash[:error] = "Request was not updated. No change specified ?"
        render :action => "edit", :id => @request.id
      end
    rescue => exception
      error_message = "An error has occurred, category:'#{exception.class}'\ndescription:'#{exception.message}'"
      EventFactory.request_update_note_to_manager(@request, current_user, error_message)
      flash[:error] = "Failed to update request. " << error_message
      render :action => "edit", :id => @request.id
    end
  end

  def show
    @request = Request.find(params[:id])
    unless @request.user_id.blank?
      @user = User.find(@request.user_id)
    end

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def additional
    @request    = Request.find(params[:id])
    @additional = @request.request_type.create!(:initial_study => @request.study, :items => @request.items)
    redirect_to request_path(@additional)
  end

  def reset
    @request = Request.find(params[:id])
    @request.reset!
    flash[:notice] = "Request #{@request.id} was reset successfully"
    if params[:study_id]
      redirect_to study_requests_path(params[:study_id])
    else
      redirect_to requests_path
    end
  end

  def cancel
    @request = Request.find(params[:id])
    if @request.cancelable?
      if  @request.cancel_before_started && @request.save
        flash[:notice] = "Request #{@request.id} has been cancelled"
        redirect_to request_path(@request)
      else
        flash[:error] = "Failed to cancel request #{@request.id}"
        redirect_to request_path(@request)
      end
    else
      flash[:notice] = "Request #{@request.id} in progress. Can't be cancelled"
      redirect_to request_path(@request)
    end
  end

  # Displays history of events
  def history
    @request = Request.find(params[:id])
    respond_to do |format|
      format.html
      format.xml  { @request.events.to_xml }
      format.json { @request.events.to_json }
    end
  end

  def list_inboxes
    @tasks = Task.all
  end

  def print
    @request = Request.find(params[:id])
  end

  def print_items
    @request   = Request.find(params[:request_id])
    printables = []
    params[:printable].each do |key, value|
      item = Item.find(key)
      printables.push PrintBarcode::Label.new({ :number => key, :study => item.name, :suffix => "" })
    end
    if !printables.empty?
      BarcodePrinter.print(printables, params[:printer])
    end
    flash[:notice] = "Your labels have been sent to printer #{params[:printer]}."
    redirect_to request_path(@request)
  rescue SOAP::FaultError
    flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
    redirect_to request_path(@request)
  end

  def expanded(options = {})
    render :text => "", :status => :gone
  end

  def pending
    render :text => "", :status => :gone
  end

  def incomplete_requests_for_family(options = {})
    render :text => "", :status => :gone
  end

  def redirect_if_not_owner_or_admin
    unless current_user == @request.user or current_user.is_administrator? or current_user.is_manager?
      flash[:error] = "Request details can only be altered by the owner or a manager"
      redirect_to request_path(@request)
      return true
    end
    false
  end

  def copy
    old_request = Request.find(params[:id])
    if old_request.has_quota?(1)
      new_request = old_request.copy
      flash[:notice] = "Created request #{new_request.id}"
      redirect_to asset_url(new_request.asset)
    else
      flash[:error] = "Insufficient quota."
      redirect_to asset_url( old_request.asset)
    end
  end

  def reset_qc_information
    @request = Request.find(params[:id])
    @request.reset!
    @event = Event.find(params[:event_id])
    flash[:notice] = "QC event #{@event.id} has been deleted"
    @event.destroy
    redirect_to request_path(@request)
  end

  # Method used to migrate MX data from studies to pipelines
  def mpx_requests_details
    @requests = Request.migrate_mpx_requests
    respond_to do |format|
      format.json { render :json => @requests.to_json }
    end
  end

  before_filter :find_request, :only => [ :filter_change_decision, :change_decision ]

  def find_request
    @request  = Request.find(params[:id])
  end

  def filter_change_decision
    reference = BillingEvent.build_reference(@request)
    #@billing  = BillingEvent.related_to_reference(reference).only_these_kinds('charge', 'refund').all
    @billing  = BillingEvent.related_to_reference(reference).all
    @change_decision = Request::ChangeDecision.new(:request => @request, :billing => @billing, :user => @current_user)
    respond_to do |format|
      format.html
    end
  end

  def change_decision
    reference = BillingEvent.build_reference(@request)
    #@billing  = BillingEvent.related_to_reference(reference).only_these_kinds('charge', 'refund').all
    @billing  = BillingEvent.related_to_reference(reference).all

    @change_decision = Request::ChangeDecision.new({:request => @request,:billing => @billing, :user => @current_user}.merge(params[:change_decision] || {})).execute!
    flash[:notice] = "Update. Below you find the new situation."
    redirect_to filter_change_decision_request_path(params[:id])
   rescue Request::ChangeDecision::InvalidDecision => exception
      flash[:error] = "Failed! Please, read the list of problem below."
      @change_decision = exception.object
      render(:action => :filter_change_decision)
  end
end
