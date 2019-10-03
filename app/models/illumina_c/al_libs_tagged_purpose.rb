# @deprecated Part of the old Generic Lims pipelines
# Tag plate in the old Generic Lims pipelines. Used by:
#
# - ILC AL Libs Tagged
# - ILC Lib Chromium
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_c/plate_purposes.rb
#           illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaC::AlLibsTaggedPurpose < PlatePurpose
  include PlatePurpose::Initial
  include PlatePurpose::Library

  include PlatePurpose::RequestAttachment

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
