# A Tube that passes through the Gatekeeper QC process
# State changes are delegated to the {Qcable}, not the transfer request.
# @note JG 2019-10-01: Currently only used for 'Tag 2 Tube'
#       which is an {Tag i5} containing tube produced by Gatekeeper.
#       The last registered tube was 2018-06-18 as these tubes have largely
#       been replaced by UDI tag sets. Removal would break:
#
#         - Use of any existing 'Tag 2 Tubes'
#         - Creation of new Tag 2 tubes via the 'Tag 2 Tubes' {LotType} in
#           Gatekeeper
class QcableTubePurpose < Tube::Purpose
  include SharedBehaviour::QcableAsset
end
