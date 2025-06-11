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

  def action_for_qc_state(state)
    ActiveRecord::Base.transaction do
      if endpoint_previously_called?
        # If the state provided in the API call (`state`) matches the one previously recorded,
        # we just continue to rendering, otherwise we raise an exception.
        raise NPGActionInvalid, conflicting_state_message(state) if existing_state != state
      else
        generate_events(state)
      end

      respond_to { |format| format.any { render template: 'assets/show', formats: [:xml] } }
    end
  end

  # Does a variety of things to do with passing / failing sequencing requests & batches, and recording an audit trail:
  # - Sets the qc_state field of the lane receptacle
  # - Sets the external_release field of the lane receptacle
  # - Creates an Event (Sequencescape, not WH) against the lane receptacle to say external_release was updated
  # - Creates an Event (Sequencescape, not WH) against the lane receptacle, with the qc_information from the API call
  # - Changes the state of the request
  # - Creates an Event (Sequencescape, not WH) against the request to record the qc complete state
  # - If all the requests in the batch are now qc'd, updates the batch state and qc_state fields
  # - Broadcasts a SequencingComplete event to the Events Warehouse
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
    # select any non-cancelled requests
    requests = @asset.requests_as_target.not_cancelled

    # throw exception if no valid requests found
    unless requests.one?
      raise ActiveRecord::RecordNotFound,
            "Unable to identify a suitable single active request for Asset: #{params[:asset_id]}"
    end

    # eager load the request to include the batch and all requests in the batch
    @request = requests.includes(batch: { requests: :asset }).first
  end

  def find_last_event
    @last_event = Event.family_pass_and_fail.npg_events(@request.id).first
  end

  # Requires a parameter to be passed in the request body, of the following form:
  # { "qc_information": { "message": "..." } }
  def qc_information
    params.require(:qc_information).permit(:message)
  end

  def rescue_error(exception)
    render xml: "<error><message>#{exception.message}</message></error>", status: :not_found
  end

  def rescue_error_bad_request(exception)
    render xml: "<error><message>#{exception.message.split("\n").first}</message></error>", status: :bad_request
  end

  # If there is already a 'pass' or 'fail' event recorded,
  # it implies this endpoint has already been called for this request.
  def endpoint_previously_called?
    @last_event.present?
  end

  # Returns the state previously recorded for the request,
  # if the endpoint has been called before.
  # Could be 'pass' or 'fail'.
  def existing_state
    @last_event.family
  end

  # Possible qc states are 'pass' and 'fail'
  def conflicting_state_message(requested_state)
    "The request on this lane has already been completed with qc state: '#{existing_state}'. " \
      "Unable to set it to new qc state: '#{requested_state}'."
  end
end
