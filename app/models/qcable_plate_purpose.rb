# frozen_string_literal: true
# Used by the tag plates generated by Gatekeeper
# Delegates state to the {Qcable} rather than the transfer requests
class QcablePlatePurpose < PlatePurpose
  include SharedBehaviour::QcableAsset
end
