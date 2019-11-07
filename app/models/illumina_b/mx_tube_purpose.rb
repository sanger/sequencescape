# @deprecated Used by 'ILB_STD_MX' part of old Illumina-B Pipeline app
# @todo #2396 Remove this class. This will involve:
#
#       - Update 'ILB_STD_MX' to use {Tube::StandardMx} instead
#       - Update or remove the factories in `app/models/illumina_b/plate_purposes.rb`
#       - Delete this file
#       - Check tests and update as appropriate. Check code coverage if removing tests.
class IlluminaB::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def stock_plate(tube)
    tube.requests_as_target.where_is_a(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end
  deprecate :stock_plate
end
