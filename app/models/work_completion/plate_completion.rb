# frozen_string_literal: true

# Class WorkCompletion::PlateCompletion provides the business logic
# for passing plates, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::PlateCompletion
  attr_reader :target_plate, :submission_ids, :order_ids

  def initialize(plate, submission_ids)
    @target_plate = plate
    @submission_ids = submission_ids
  end

  def process
    connect_requests
    update_stock_wells
  end

  # Updates the source receptacle (asset) of the downstream requests (e.g. sequencing requests).
  # Passes the requests coming into this labware's receptacles (library requests).
  # Collects order_ids, as the WorkCompletion class needs these to fire events.
  #
  def connect_requests
    target_wells.each do |target_well|
      detect_upstream_requests(target_well).each do |upstream|
        @order_ids << upstream.order_id

        # We need to find the downstream requests BEFORE connecting the upstream
        # This is because submission.next_requests tries to take a shortcut through
        # the target_asset if it is defined.
        upstream.next_requests.each { |ds| ds.update!(asset: target_well) }

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
    @order_ids.uniq!
  end

  def target_wells
    @target_wells ||=
      target_plate
        .wells
        .includes(aliquots: { request: WorkCompletion::REQUEST_INCLUDES })
        .include_stock_wells_for_modification
        .where(requests: { submission_id: submission_ids })
  end

  def detect_upstream_requests(target_well)
    target_well.aliquots.map(&:request)
  end

  # The wells on this plate are now considered the 'stock wells' of any downstream of them.
  def update_stock_wells
    Well::Link.stock.where(target_well_id: target_wells.map(&:id)).delete_all
    Well::Link.stock.import(target_wells.map { |well| { source_well_id: well.id, target_well_id: well.id } })
  end
end
