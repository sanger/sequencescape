# frozen_string_literal: true
# Processes {CherrypickRequest}
# Allows material from {Well wells} on one or more source {Plate plates} to be
# laid out onto either a NEW plate of a specified {PlatePurpose} or onto a plate
# created as part of an earlier cherrypick.
#
# WARNING! {CherrypickRequest Cherrypick requests} create their target wells upfront
# and are laid out onto otherwise well-less plates. This results in odd behaviour:
#  - You cannot cherrypick onto plates with all their wells, even if those wells are empty
#  - Prior to processing, wells attached to {CherrypickRequest cherrypick requests} will not
#    be assigned to a plate.
#  - Occasionally it is possible to pick two wells to the same location. This does not result in
#    pooling or a tag clash, but rather two wells with the same location on the same plate.
#
# @note Cherrypicking is typically processed by an SSR, and the batch worksheet is passed over to the lab.
#       Actual lab work is tracked via {Robot::Verification::Base} classes through the {RobotVerificationsController}
class CherrypickPipeline < CherrypickingPipeline
  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, _user) # rubocop:todo Metrics/MethodLength
    target_purpose = batch.output_plates.first.purpose.name

    # stock wells
    batch
      .requests
      .select(&:passed?)
      .each do |request|
        request
          .asset
          .stock_wells
          .each { |stock| EventSender.send_pick_event(stock, target_purpose, "Pickup well #{request.asset.id}") }
      end
    batch.release_pending_requests
    batch.output_plates.each(&:cherrypick_completed)
  end
end
