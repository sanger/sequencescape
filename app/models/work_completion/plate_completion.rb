# frozen_string_literal: true

# Class WorkCompletion::PlateCompletion provides the business logic
# for passing plates, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::PlateCompletion < WorkCompletion::LabwareCompletion
  def process
    super
    update_stock_wells
  end

  def connect_requests
    target_wells.each do |target_well|
      detect_upstream_requests(target_well).each { |upstream| pass_and_link_up_requests(target_well, upstream) }
    end
    @order_ids.uniq!
  end

  def target_wells
    @target_wells ||=
      target_labware
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
