# frozen_string_literal: true

# Class WorkCompletion::PlateCompletion provides the business logic
# for passing plates, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::TubeCompletion
  attr_reader :target_tube, :submission_ids

  def initialize(tube, submission_ids)
    @target_tube = tube
    @submission_ids = submission_ids
  end

  def process
    connect_requests
  end

  def connect_requests
    # Upstream requests our on our stock wells.
    detect_upstream_requests.each do |upstream|
      # We need to find the downstream requests BEFORE connecting the upstream
      # This is because submission.next_requests tries to take a shortcut through
      # the target_asset if it is defined.
      downstream = upstream.submission.next_requests(upstream)
      downstream.each { |ds| ds.update_attributes!(asset: target_tube) }
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

  # This method is probably horrifically broken.
  # It is also dependant of requests being from wells
  def detect_upstream_requests
    wells = collect_upstream_wells([], target_tube)
    # Not great, but substantially faster than the alternative of just grabbing
    # everything through well.
    CustomerRequest.includes(:submission, source_well: { target_wells: :submissions })
                   .where(target_wells_assets: { id: wells })
                   .where('requests.submission_id = transfer_requests.submission_id')
  end

  # This isn't very OO. I'm trying to keep the horror confined until
  # we have a stable solution
  def collect_upstream_wells(collection, asset)
    if asset.is_a?(Well)
      collection << asset
    else
      asset.upstream_assets.each { |next_asset| collect_upstream_wells(collection, next_asset) }
    end
    collection
  end
end
