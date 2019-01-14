require 'event_factory'
class RequestsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  before_action :admin_login_required, only: [:describe, :undescribe, :destroy]
  before_action :set_permitted_params, only: [:update]

  def set_permitted_params
    @parameters = params[:request].reject { |k, _v| !['request_metadata_attributes'].include?(k.to_s) }
  end
  attr_reader :parameters
  # before_action :find_request_from_id, :only => [ :filter_change_decision, :change_decision ]

  def index
    @study, @item = nil, nil

    # Ok, here we pick the initial source for the Requests.  They either come from Request (as in all Requests), or they
    # are limited by the Asset / Item.
    request_source = Request.includes(:request_type, :initial_study, :user, :events, asset: :barcodes)
                            .order(id: :desc)
                            .where(search_params)
                            .paginate(per_page: 200, page: params[:page])

    @asset        = Asset.find(params[:asset_id]) if params[:asset_id]
    @request_type = RequestType.find(params[:request_type_id]) if params[:request_type_id]
    @study        = Study.find(params[:study_id]) if params[:study_id]

    @subtitle = (@study&.name || @asset&.display_name)

    # Deprecated?: It would be great if we could remove this
    if params[:request_type] and params[:workflow]
      request_source = request_source.for_request_types(params[:request_type]).includes(:user)
    end

    # Now, here we go: find all of the requests!
    @requests = request_source

    respond_to do |format|
      format.html
      format.xml { render xml: Request.all.to_xml }
    end
  end

  def edit
    @request = Request.find(params[:id])
    @request_types = RequestType.where(asset_type: @request.request_type.asset_type)
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

    unless params[:request][:request_type_id].nil?
      unless @request.request_type_updatable?(params[:request][:request_type_id])
        flash[:error] = 'You can not change the request type.'
        redirect_to request_path(@request)
        return
      end
    end

    begin
      if @request.update(parameters)
        flash[:notice] = 'Request details have been updated'
        redirect_to request_path(@request)
      else
        flash[:error] = 'Request was not updated. No change specified ?'
        render action: 'edit', id: @request.id
      end
    rescue => exception
      error_message = "An error has occurred, category:'#{exception.class}'\ndescription:'#{exception.message}'"
      EventFactory.request_update_note_to_manager(@request, current_user, error_message)
      flash[:error] = 'Failed to update request. ' << error_message
      render action: 'edit', id: @request.id
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
    @additional = @request.request_type.create!(initial_study: @request.study, items: @request.items)
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
    if @request.try(:may_cancel_before_started?)
      if @request.cancel_before_started && @request.save
        flash[:notice] = "Request #{@request.id} has been cancelled"
      else
        flash[:error] = "Failed to cancel request #{@request.id}"
      end
    else
      flash[:error] = "Request #{@request.id} can't be cancelled"
    end
    redirect_to request_path(@request)
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

  def redirect_if_not_owner_or_admin
    unless current_user == @request.user or current_user.is_administrator? or current_user.is_manager?
      flash[:error] = 'Request details can only be altered by the owner or a manager'
      redirect_to request_path(@request)
      return true
    end
    false
  end

  def copy
    old_request = Request.find(params[:id])
    new_request = old_request.copy
    flash[:notice] = "Created request #{new_request.id}"
    redirect_to asset_url(new_request.asset)
  end

  def reset_qc_information
    @request = Request.find(params[:id])
    @request.reset!
    @event = Event.find(params[:event_id])
    flash[:notice] = "QC event #{@event.id} has been deleted"
    @event.destroy
    redirect_to request_path(@request)
  end

  before_action :find_request, only: [:filter_change_decision, :change_decision]

  def find_request
    @request = Request.find(params[:id])
  end

  def filter_change_decision
    @change_decision = Request::ChangeDecision.new(request: @request, user: @current_user)
    respond_to do |format|
      format.html
    end
  end

  def change_decision
    @change_decision = Request::ChangeDecision.new({ request: @request, user: @current_user }.merge(params[:change_decision] || {})).execute!
    flash[:notice] = 'Update. Below you find the new situation.'
    redirect_to filter_change_decision_request_path(params[:id])
  rescue Request::ChangeDecision::InvalidDecision => exception
    flash[:error] = 'Failed! Please, read the list of problem below.'
    @change_decision = exception.object
    render(action: :filter_change_decision)
  end

  def search_params
    permitted = params.permit(:asset_id, :state, :request_type_id, :submission_id)
    permitted[:initial_study_id] = params[:study_id] if params[:study_id]
    permitted
  end
end
