# @deprecated Part of the old Illumina-B Lims pipelines
# Normalization plate for a plate based normalization and pooling strategy.
#
# - Lib Norm 2
#
# @todo #2396 Remove this class. This will require:
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::NormalizedPlatePurpose < PlatePurpose
  include PlatePurpose::RequestAttachment
  include PlatePurpose::BroadcastLibraryComplete

  self.connect_on = 'passed'
  self.connect_downstream = false
end
