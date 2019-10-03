# @deprecated Part of the old Illumina-B Lims pipelines
# Plate type formerly used by:
#
# - PF Lib XP2
#
# Now entirely unused.
#
# @todo #2396 Remove from code. This will require:
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#           app/models/pulldown/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::LibraryCompleteOnQcPurpose < PlatePurpose
  include PlatePurpose::Library
  include PlatePurpose::RequestAttachment
  include PlatePurpose::BroadcastLibraryComplete

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
