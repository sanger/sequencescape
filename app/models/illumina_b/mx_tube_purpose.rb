# @deprecated Used by 'ILB_STD_MX' part of old Illumina-B Pipeline app
# @todo #2396 Remove this class. This will involve:
#
#       - Update 'ILB_STD_MX' to use {Tube::StandardMx} instead
#       - Update or remove the factories in `app/models/illumina_b/plate_purposes.rb`
#       - Delete this file
#       - Check tests and update as appropriate. Check code coverage if removing tests.
class IlluminaB::MxTubePurpose < IlluminaHtp::MxTubePurpose
  #
  # Attempts to find the 'stock_plate' for a given tube. However this is a fairly
  # nebulous concept. Often it means the plate that first entered a pipeline,
  # but in other cases it can be the XP plate part way through the process. Further
  # complication comes from tubes which pool across multiple plates, where identifying
  # a single stock plate is meaningless. In other scenarios, you split plates out again
  # and the asset link graph is insufficient.
  #
  # JG: 2021-02-11: In this case we attempt to jump back through the requests. In most
  # limber pipelines this will actually return the plate on which you charge and pass.
  # See https://github.com/sanger/sequencescape/issues/3040 for more information
  #
  # @deprecate Do not use this for new behaviour.
  #
  # @param tube [Tube] The tube for which to find the stock_plate
  #
  # @return [Plate, nil] The stock plate if found
  #
  def stock_plate(tube)
    tube.requests_as_target.where_is_a(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end
  deprecate stock_plate: 'Stock plate is nebulous and can easily lead to unexpected behaviour'
end
