# frozen_string_literal: true

# Takes QC decisions on lanes from NPG and records the
# information in Sequencescape, passing the requests and creating
# events as required.
class NpgActions::AssetsController < ApplicationController
  # Raised if an action is performed which contradicts a previous one
  NPGActionInvalid = Class.new(StandardError)

  before_action :login_required, except: %i[pass fail]
  before_action :find_asset, only: %i[pass fail]
  before_action :find_request, only: %i[pass fail]
  before_action :find_last_event, only: %i[pass fail]
  before_action :qc_information, only: %i[pass fail]

  rescue_from(ActiveRecord::RecordNotFound, with: :rescue_error)
  rescue_from(NPGActionInvalid, ActionController::ParameterMissing, with: :rescue_error_bad_request)

  def fail
    action_for_qc_state('fail')
  end

  def pass
    action_for_qc_state('pass')
  end

  private

  def action_for_qc_state(state) # rubocop:todo Metrics/MethodLength
    ActiveRecord::Base.transaction do
      if @last_event.present?
        # If we already have an event we check to see its state. If it matches,
        # we just continue to rendering, otherwise we blow up.
        raise NPGActionInvalid, 'NPG user run this action. Please, contact USG' if @last_event.family != state
      else
        generate_events(state)
      end

      respond_to do |format|
        format.xml { render file: 'assets/show' }
        format.html { render template: 'assets/show.xml.builder' }
      end
    end
  end

  def generate_events(state)
    state_str = "#{state}ed"
    batch = @request.batch || raise(ActiveRecord::RecordNotFound, 'Unable to find a batch for the Request')

    @asset.set_qc_state(state_str)

    @asset.events.create_state_update!(qc_information[:message] || 'No reason given')

    message = "#{state}ed manual QC".capitalize
    EventSender.send_state_event(state, @request, '', message, '', 'npg')

    batch.npg_set_state

    BroadcastEvent::SequencingComplete.create!(seed: @asset, properties: { result: state_str })
  end

  def find_asset
    @asset = Lane.find(params[:asset_id])
  end

  def find_request
    requests = @asset.requests_as_target
    raise ActiveRecord::RecordNotFound, "Unable to find a request for Asset: #{params[:id]}" unless requests.one?

    @request = requests.includes(batch: { requests: :asset }).first
  end

  def find_last_event
    @last_event = Event.family_pass_and_fail.npg_events(@request.id).first
  end

  def qc_information
    params.require(:qc_information).permit(:message)
  end

  def rescue_error(exception)
    render xml: "<error><message>#{exception.message}</message></error>", status: '404'
  end

  def rescue_error_bad_request(exception)
    render xml: "<error><message>#{exception.message}</message></error>", status: '400'
  end
end
