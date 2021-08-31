# frozen_string_literal: true
# Used by 'Tag PCR' plates created by Gatekeeper
# This is part of the gatekeeper QC Pipeline.
# Delegates state to the associated qc-able, rather than the transfer requests
class QcableLibraryPlatePurpose < PlatePurpose
  self.state_changer = StateChanger::QcableLibraryPlate

  def state_of(plate)
    qcable_for(plate).state
  end

  private

  def qcable_for(plate)
    Qcable.find_by(asset_id: plate.id)
  end
end
