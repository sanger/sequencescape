# frozen_string_literal: true

# Class WorkCompletion::PlateCompletion provides the business logic
# for passing plates, especially in the Limber pipelines. This has
# been pulled out of WorkCompletion itself to allow for separate behaviour
# for plates and tubes.
#
# @author Genome Research Ltd.
#
class WorkCompletion::PlateCompletion
  attr_reader :target_plate, :submission_ids, :user

  def initialize(plate, submission_ids, user)
    @target_plate = plate
    @submission_ids = submission_ids
    @user = user
  end

  def process
    connect_requests
    update_stock_wells
    fire_events
  end

  def connect_requests
    target_wells.each do |target_well|
      detect_upstream_requests(target_well).each do |upstream|
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
  end

  def detect_upstream_requests(target_well)
    target_well.aliquots.map(&:request)
  end

  def suitable_request?(request)
    submission_ids.include?(request.submission_id)
  end

  def update_stock_wells
    Well::Link.stock.where(target_well_id: target_wells.map(&:id)).delete_all
    Well::Link.stock.import(target_wells.map { |well| { source_well_id: well.id, target_well_id: well.id } })
  end

  def target_wells
    @target_wells ||=
      target_plate
        .wells
        .includes(aliquots: { request: WorkCompletion::REQUEST_INCLUDES })
        .include_stock_wells_for_modification
        .where(requests: { submission_id: submission_ids })
  end

  def fire_events
    order_ids.each do |order_id|
      BroadcastEvent::LibraryComplete.create!(seed: target_plate, user: user, properties: { order_id: order_id })
    end
  end

  def order_ids
    output = []
    target_wells.each do |target_well|
      detect_upstream_requests(target_well).each { |upstream| output << upstream.order_id }
    end
    output.uniq
  end
end
