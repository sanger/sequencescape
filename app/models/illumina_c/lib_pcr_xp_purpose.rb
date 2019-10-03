# @deprecated Part of the old Generic Lims pipelines
# FInal plate in the old Generic Lims pipelines. Used by:
#
# - ILC Lib PCR-XP
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_c/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaC::LibPcrXpPurpose < PlatePurpose
  include PlatePurpose::RequestAttachment

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
