# frozen_string_literal: true

# Class WorkCompletion::PlateCompletion provides the business logic
# for passing plates, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::PlateCompletion
  attr_reader :target_plate, :submission_ids

  def initialize(plate, submission_ids)
    @target_plate = plate
    @submission_ids = submission_ids
  end

  def process
    connect_requests
    update_stock_wells
  end

  def connect_requests
    target_wells.each do |target_well|
      next if target_well.stock_wells.empty?
      # Upstream requests our on our stock wells.
      detect_upstream_requests(target_well).each do |upstream|
        # We need to find the downstream requests BEFORE connecting the upstream
        # This is because submission.next_requests tries to take a shortcut through
        # the target_asset if it is defined.
        downstream = upstream.submission.next_requests(upstream)
        downstream.each { |ds| ds.update_attributes!(asset: target_well) }
        # In some cases, such as the Illumina-C pipelines, requests might be
        # connected upfront. We don't want to touch these.
        upstream.target_asset ||= target_well
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
  end

  def detect_upstream_requests(target_well)
    upstream_requests = target_well.stock_wells.each_with_object([]) do |source_well, found_upstream_requests|
      # We may have multiple requests out of each well, however we're only concerned
      # about those associated with the active submission.
      # We've already eager loaded requests out of the stock wells, so filter in Ruby.
      source_well.requests_as_source.each do |r|
        found_upstream_requests << r if suitable_request?(r)
      end
    end
    # We've looked at all the requests, on all the stock wells and still haven't found
    # what we're looking for.
    raise("Could not find matching upstream requests for #{target_well.map_description}") if upstream_requests.empty?
    upstream_requests
  end

  def suitable_request?(request)
    submission_ids.include?(request.submission_id)
  end

  def update_stock_wells
    Well::Link.stock.where(target_well_id: target_wells.map(&:id)).delete_all
    Well::Link.stock.import(target_wells.map { |well| { source_well_id: well.id, target_well_id: well.id } })
  end

  def target_wells
    @target_wells ||= target_plate.wells
                                  .includes(:aliquots)
                                  .include_stock_wells_for_modification
                                  .includes(:transfer_requests_as_target)
                                  .where(transfer_requests: { submission_id: submission_ids })
  end
end
