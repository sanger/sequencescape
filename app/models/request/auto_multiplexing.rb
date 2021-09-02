# frozen_string_literal: true
# In the Generic Lims, transfer into the Multiplexed library tube is triggered
# automatically when the plate is passed. However, if multiplexing decisions
# are made after library creation, this step has already taken place. This
# callback ensure that the tube are generated after the submission is complete.
# The user may then log into generic Lims to see their plates.
# This issue is avoided in Limber by decoupling tube creation from plate passing
# allowing the step to be repeated at any time. This class can be removed if either
# the generic LIMS behaviour is updated, or moved into Limber.
class Request::AutoMultiplexing < Request::Multiplexing
  after_create :register_transfer_callback

  # Triggers immediate transfer into the tubes if the source asset already
  # exists. This allows multiplexing requests to be made on plates at the
  # end of library prep, after the plate is qc_complete.
  # If no asset is present then we haven't got to that stage yet and transfer
  # will be triggered as part of the standard workflow.
  def register_transfer_callback
    # We go via order as we need to get a particular instance of submission
    return if asset.blank?

    order
      .submission
      .register_callback(:once) { Transfer::FromPlateToTubeByMultiplex.create!(source: asset.plate, user: order.user) }
  end
end
