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
    detect_upstream_requests(target_tube).each do |upstream|
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
  def detect_upstream_requests(target_tube)
    # upstream_requests = target_tube.stock_wells.each_with_object([]) do |source_well, found_upstream_requests|
    #   # We may have multiple requests out of each well, however we're only concerned
    #   # about those associated with the active submission.
    #   # We've already eager loaded requests out of the stock wells, so filter in Ruby.
    #   source_well.requests_as_source.each do |r|
    #     found_upstream_requests << r if suitable_request?(r)
    #   end
    # end
    # # We've looked at all the requests, on all the stock wells and still haven't found
    # # what we're looking for.
    # raise("Could not find matching upstream requests for #{target_tube.map_description}") if upstream_requests.empty?
    # upstream_requests
    wells = collect_upstream_wells([], target_tube)
    wells.reduce([]) do |requests, well|
      requests + well.outer_requests.where(submission_id: well.submissions)
    end
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
