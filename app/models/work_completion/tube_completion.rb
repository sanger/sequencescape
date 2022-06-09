# frozen_string_literal: true

# Class WorkCompletion::TubeCompletion provides the business logic
# for passing tubes, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::TubeCompletion
  attr_reader :target_tube, :submission_ids, :order_ids

  def initialize(tube, submission_ids)
    @target_tube = tube
    @submission_ids = submission_ids
    @order_ids = []
  end

  def process
    connect_requests
  end

  # Updates the source receptacle (asset) of the downstream requests (e.g. sequencing requests).
  # Passes the requests coming into this labware's receptacles (library requests).
  # Collects order_ids, as the WorkCompletion class needs these to fire events.
  #
  def connect_requests
    # Upstream requests out of our stock wells.
    detect_upstream_requests.each do |upstream|
      @order_ids << upstream.order_id

      # We need to find the downstream requests BEFORE connecting the upstream
      # This is because submission.next_requests tries to take a shortcut through
      # the target_asset if it is defined.

      # Works, even though 'asset' expects a receptacle, and it is being passed a labware.
      upstream.next_requests.each { |ds| ds.update!(asset: target_tube) }

      # In some cases, such as the Illumina-C pipelines, requests might be
      # connected upfront. We don't want to touch these.
      upstream.target_asset ||= target_tube

      # We don't try and pass failed requests.
      # I'm not 100% convinced this decision belongs here, and instead
      # we may want to let the client specify wells to pass, and perform
      # validation to ensure this is correct. However this increases
      # the complexity of both the code and the interface, with only
      # marginal system simplification.
      upstream.pass if upstream.may_pass?
      upstream.save!
    end
    @order_ids.uniq!
  end

  def detect_upstream_requests
    CustomerRequest.includes(WorkCompletion::REQUEST_INCLUDES).where(id: target_tube.aliquots.pluck(:request_id))
  end
end
