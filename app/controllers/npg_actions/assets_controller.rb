
class NpgActions::AssetsController < ApplicationController
  before_action :login_required, except: [:pass, :fail]
  before_action :find_asset, only: [:pass, :fail]
  before_action :find_request, only: [:pass, :fail]
  before_action :npg_action_invalid?, only: [:pass, :fail]
  before_action :xml_valid?, only: [:pass, :fail]

  rescue_from(ActiveRecord::RecordNotFound, with: :rescue_error)

  XmlInvalid = Class.new(StandardError)
  rescue_from(XmlInvalid, with: :rescue_error)

  NPGActionInvalid = Class.new(StandardError)
  rescue_from(NPGActionInvalid, with: :rescue_error_internal_server_error)

  def fail
    action_for_qc_state('fail', :create_fail!, :send_fail_event)
  end

  def pass
    action_for_qc_state('pass', :create_pass!, :send_pass_event)
  end

  private

  def action_for_qc_state(state, create_method_name, send_method_name)
    ActiveRecord::Base.transaction do
      state_str = "#{state}ed"
      @asset.set_qc_state(state_str)
      create_method = @asset.events.method(create_method_name)
      send_method = EventSender.method(send_method_name)

      create_method.call(params[:qc_information][:message] || 'No reason given')

      request = @asset.source_request
      batch = request.batch
      raise ActiveRecord::RecordNotFound, 'Unable to find a batch for the Request' if (batch.nil?)

      message = "#{state}ed manual QC".capitalize
      send_method.call(request.id, '', message, '', 'npg', need_to_know_exceptions: true)

      batch.npg_set_state if (state == 'pass')
      BroadcastEvent::SequencingComplete.create!(seed: @asset,
                                                 properties: { result: state_str })

      respond_to do |format|
        format.xml  { render file: 'assets/show' }
        format.html { render template: 'assets/show.xml.builder' }
      end
    end
  end

  def find_asset
    @asset ||= Lane.find(params[:asset_id])
  end

  def find_request
    @asset ||= Lane.find(params[:asset_id])
    if ((@asset.has_many_requests?) || (@asset.source_request.nil?))
      raise ActiveRecord::RecordNotFound, "Unable to find a request for Asset: #{params[:id]}"
    end
  end

  def xml_valid?
    raise XmlInvalid, 'XML invalid' if params[:qc_information].nil?
  end

  def npg_action_invalid?
    @asset ||= Lane.find(params[:asset_id])
    request = @asset.source_request
    npg_events = Event.npg_events(request.id)
    raise NPGActionInvalid, 'NPG user run this action. Please, contact USG' if npg_events.exists?
  end

  def rescue_error(exception)
    respond_to do |format|
      format.html { render xml: "<error><message>#{exception.message}</message></error>", status: '404' }
      format.xml { render xml: "<error><message>#{exception.message}</message></error>", status: '404' }
    end
  end

  def rescue_error_internal_server_error(exception)
    respond_to do |format|
      format.html { render xml: "<error><message>#{exception.message}</message></error>", status: '500' }
      format.xml { render xml: "<error><message>#{exception.message}</message></error>", status: '500' }
    end
  end
end
