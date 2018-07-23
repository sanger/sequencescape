# frozen_string_literal: true

# Takes QC decisions on lanes from NPG and records the
# information in Sequencescape, passing the requests and creating
# events as required.
class NpgActions::AssetsController < ApplicationController
  before_action :login_required, except: [:pass, :fail]
  before_action :find_asset, only: [:pass, :fail]
  before_action :find_request, only: [:pass, :fail]
  before_action :find_last_event, only: [:pass, :fail]
  before_action :xml_valid?, only: [:pass, :fail]

  rescue_from(ActiveRecord::RecordNotFound, with: :rescue_error)

  XmlInvalid = Class.new(StandardError)
  rescue_from(XmlInvalid, with: :rescue_error)

  NPGActionInvalid = Class.new(StandardError)
  rescue_from(NPGActionInvalid, with: :rescue_error_bad_request)

  def fail
    action_for_qc_state('fail', :create_fail!, :send_fail_event)
  end

  def pass
    action_for_qc_state('pass', :create_pass!, :send_pass_event)
  end

  private

  def action_for_qc_state(state, create_method_name, send_method_name)
    ActiveRecord::Base.transaction do
      if @last_npg_event.present?
        # If we already have an event we check to see its state. If it matches,
        # we just continue to rendering, otherwise we blow up.
        raise NPGActionInvalid, 'NPG user run this action. Please, contact USG' if @last_npg_event.family != state
      else
        state_str = "#{state}ed"
        batch = @request.batch
        raise ActiveRecord::RecordNotFound, 'Unable to find a batch for the Request' if (batch.nil?)

        @asset.set_qc_state(state_str)

        @asset.events.send(
          create_method_name,
          params[:qc_information][:message] || 'No reason given'
        )

        message = "#{state}ed manual QC".capitalize
        EventSender.send(send_method_name, @request.id, '', message, '', 'npg')

        batch.npg_set_state

        BroadcastEvent::SequencingComplete.create!(seed: @asset,
                                                   properties: { result: state_str })
      end

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
    unless @asset.requests_as_target.one?
      raise ActiveRecord::RecordNotFound, "Unable to find a request for Asset: #{params[:id]}"
    end
    @request ||= @asset.requests_as_target.includes(batch: { requests: :asset }).first
  end

  def xml_valid?
    raise XmlInvalid, 'XML invalid' if params[:qc_information].nil?
  end

  def find_last_event
    @last_npg_event = Event.family_pass_and_fail
                           .npg_events(@request.id)
                           .first
  end

  def rescue_error(exception)
    render xml: "<error><message>#{exception.message}</message></error>", status: '404'
  end

  def rescue_error_bad_request(exception)
    render xml: "<error><message>#{exception.message}</message></error>", status: '400'
  end
end
