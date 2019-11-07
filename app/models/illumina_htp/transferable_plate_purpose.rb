# @deprecated Part of the old Illumina-B Lims pipelines
# Plate type used to bridge the top and bottom halves of the pipeline
#
# - Lib PCR-XP
# - Lib PCRR-XP
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::TransferablePlatePurpose < IlluminaHtp::FinalPlatePurpose
  include PlatePurpose::RequestAttachment
  include PlatePurpose::WorksOnLibraryRequests

  self.connect_on = 'qc_complete'
  self.connect_downstream = true

  def source_wells_for(wells)
    Well.in_column_major_order.stock_wells_for(wells)
  end
end
