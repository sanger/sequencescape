# frozen_string_literal: true

# Shared behaviour of WorkCompletion::PlateCompletion and WorkCompletion::TubeCompletion
# and WorkCompletion::TubeRackCompletion
#
# @author Genome Research Ltd.
#
class WorkCompletion::LabwareCompletion
  attr_reader :target_labware, :submission_ids, :order_ids, :work_completion

  def initialize(labware, submission_ids, work_completion)
    @target_labware = labware
    @submission_ids = submission_ids
    @order_ids = []
    @work_completion = work_completion
  end

  # This function is called by the state machine.
  # See app/models/submission/state_machine.rb.
  def process
    connect_requests
    fire_events
  end

  # Must be implemented by any subclass.
  # Finds the relevant target receptacle(s) and the requests coming into them.
  # Calls pass_and_link_up_requests for each of them.
  # Implemented differently for Plates and Tubes.
  def connect_requests
    raise NotImplementedError, 'abstract method'
  end

  # Updates the source receptacle (asset) of the downstream (normally sequencing) requests.
  # Passes the requests coming into this labware's receptacles (library requests).
  # Collects order_ids, as these are needed to fire events.
  #
  # This is called when "charge and pass" is performed on the target labware.
  #
  def pass_and_link_up_requests(target_receptacle, upstream_request)
    @order_ids << upstream_request.order_id

    # We need to find the downstream requests BEFORE connecting the upstream_request
    # This is because submission.next_requests tries to take a shortcut through
    # the target_asset if it is defined.
    upstream_request.next_requests.each { |ds| ds.update!(asset: target_receptacle) }

    # In some cases, such as the Illumina-C pipelines, requests might be
    # connected upfront. We don't want to touch these.
    upstream_request.target_asset ||= target_receptacle

    # We don't try and pass failed requests.
    # I'm not 100% convinced this decision belongs here, and instead
    # we may want to let the client specify wells to pass, and perform
    # validation to ensure this is correct. However this increases
    # the complexity of both the code and the interface, with only
    # marginal system simplification.
    upstream_request.pass if upstream_request.may_pass?
    upstream_request.save!
  end

  def fire_events
    order_ids.each do |order_id|
      BroadcastEvent::LibraryComplete.create!(
        seed: work_completion,
        user: work_completion.user,
        properties: {
          order_id:
        }
      )
    end
  end
end
