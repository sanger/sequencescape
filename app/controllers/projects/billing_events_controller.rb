# Projects::BillingEventsController is the remote interface for third party
# applications to register that some chargable event has occured and should
# be billed to the project.
#
# Since projects act as a cost centre for a project, a BillingEvent must always
# be associated with a Project.
#
# Each billing event has the following required values:
# * An <tt>reference</tt> is a distinct reference that should universally
#   identify <em>what</em> a particular charge is for.
#   It may only be repeated for the refund
# * An <tt>description</tt> is a verbose description to ensure the reason
#   for the charge can be understood when the BillingEvent is looked at out of
#   context.
#
# All other values are general strings since they need to take charges from
# external systems from users without local accounts.
#
# Reporting for BillingEvents is not an internal function of Sequencescape
# this data is used to create a monthly export to a datawarehouse for reporting
# The reference and description should be clear enough that an external report
# will allow an invoice to be correctly generated without access to Sequencescape
#
class Projects::BillingEventsController < ApplicationController
  before_filter :get_project_id

  def index
    @billing_events = @project.billing_events

    respond_to do |format|
      format.html
      format.xml  { render :xml => @billing_events.to_xml }
      format.json { render :json => @billing_events.to_json }
    end
  end

  def show
    @billing_event = BillingEvent.find params[:id]

    if @billing_event.charge?
      @refunded_events = BillingEvent.refunds_for_reference(@billing_event.reference)
    else
      @charged_event = BillingEvent.charge_for_reference(@billing_event.reference)
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @billing_event.to_xml }
      format.json { render :json => @billing_event.to_json }
    end
  end

  def new
    @billing_event = BillingEvent.new
  end

  def create
    billing_event_attributes = params[:billing_event] ||= {}
    billing_event_attributes[:project] = @project

    # Multple respond_to blocks are troublesome.
    if request.format == "*/*"
      created_by = current_user.email || current_user.login || "Unknown - login error!"
      billing_event_attributes[:created_by] = current_user.email
    end

    begin
      @billing_event = BillingEvent.create(billing_event_attributes)
    rescue BillingException::DuplicateRefund
      respond_to do |format|
        format.html do
          flash[:errors] = I18n.t("projects.billing_events.duplicate_refund_attempt")
          render :action => "new" and return
        end
        format.xml do
          render :xml => {"error" => I18n.t("projects.billing_events.duplicate_refund_attempt")}.to_xml(:root => :errors), :status => :bad_request and return
        end
        format.json do
          render :json => {"error" => I18n.t("projects.billing_events.duplicate_refund_attempt")}.to_json, :status => :bad_request and return
        end
      end
    rescue BillingException::UnchargedRefund
      respond_to do |format|
        format.html do
          @billing_event = BillingEvent.new(params[:billing_event])
          flash[:errors] = I18n.t("projects.billing_events.no_charge_refund_attempt")
          render :action => "new" and return
        end
        format.xml do
          render :xml => {"error" => I18n.t("projects.billing_events.no_charge_refund_attempt")}.to_xml(:root => :errors), :status => :bad_request and return
        end
        format.json do
          render :json => {"error" => I18n.t("projects.billing_events.no_charge_refund_attempt")}.to_json, :status => :bad_request and return
        end
      end
    end

    respond_to do |format|
      format.html do
        unless @billing_event.valid?
          flash[:errors] = I18n.t("projects.billing_events.not_created")
          render :action => "new" and return
        else
          flash[:notice] = I18n.t("projects.billing_events.created", :ref => @billing_event.reference)
          redirect_to project_billing_event_path(@project, @billing_event)
        end
      end
      format.xml do
        unless @billing_event.valid?
          render :xml => @billing_event.errors.to_xml, :status => :bad_request
        else
          render :xml => @billing_event.to_xml, :status => :created, :location => project_billing_event_url(@project, @billing_event)
        end
      end
      format.json do
        unless @billing_event.valid?
          render :json => @billing_event.errors.to_json, :status => :bad_request
        else
          render :json => @billing_event.to_json, :status => :created, :location => project_billing_event_url(@project, @billing_event)
        end
      end
    end
  end

  private

  def get_project_id
    @project = Project.find(params[:project_id])
  end
end
