# The first plate created from the stock plate during library preparation
# Used by:
#
# - ILB_STD_COVARIS (No longer used)
# - Shear (No longer used)
# - ILC AL Libs (No longer used)
# - PF Shear
#
# Triggers library start when the plate is started
#
# This behaviour is probably redundant now, as this is handled by the transfer requests.
#
# @todo #2396 Confirm removal does not affect Limber 'High Throughput PCR Free 96' pipeline, then remove.
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_b/plate_purposes.rb
#           app/models/illumina_c/plate_purposes.rb
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class PlatePurpose::InitialPurpose < PlatePurpose
  include PlatePurpose::Initial
end
