# frozen_string_literal: true

# Class WorkCompletion::TubeCompletion provides the business logic
# for passing tubes, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::TubeCompletion
  attr_reader :target_tube, :submission_ids, :user

  def initialize(tube, submission_ids, user)
    @target_tube = tube
    @submission_ids = submission_ids
    @user = user
  end

  def process
    connect_requests
    fire_events
  end

  def connect_requests
    # Upstream requests our on our stock wells.
    detect_upstream_requests.each do |upstream|
      # We need to find the downstream requests BEFORE connecting the upstream
      # This is because submission.next_requests tries to take a shortcut through
      # the target_asset if it is defined.
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
  end

  def detect_upstream_requests
    CustomerRequest.includes(WorkCompletion::REQUEST_INCLUDES).where(id: target_tube.aliquots.pluck(:request_id))
  end

  def fire_events
    order_ids.each do |order_id|
      BroadcastEvent::LibraryComplete.create!(seed: target_tube, user: user, properties: { order_id: order_id })
    end
  end

  def order_ids
    output = []
    detect_upstream_requests.each { |upstream| output << upstream.order_id }
    output.uniq
  end
end
