# @deprecated Part of the old Illumina-B Lims pipelines
# Plate type used in the bottom half of the ISC pipeline
#
# - ISCH hyb
# - ISCH cap lib
# - ISCH cap lib PCR
# - ISCH cap lib PCR-XP
# - ISCH cap lib pool
#
# @todo #2396 Remove this class. This will require:
#
#       - Update any purposes using this class to use PlatePurpose instead
#       - Remove the IlluminaHtp::InitialDownstreamPlatePurpose class as well
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#           app/models/pulldown/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::DownstreamPlatePurpose < PlatePurpose
  def source_wells_for(stock_wells)
    Well.in_column_major_order.stock_wells_for(stock_wells)
  end

  def library_source_plates(plate)
    super.map(&:source_plates).flatten.uniq
  end

  def library_source_plate(plate)
    super.source_plate
  end
end
