# Purpose for the {MultiplexedLibraryTube} at the end of the Illumina C pipeline
# The only purpose using this is 'ILC Lib Pool Norm'
#
# @deprecated The pipleine associated with this purpose is no longer used
#
# @todo Remove this class. This will involve:
#
#       - Update 'ILC Lib Pool Norm' to use {Tube::StandardMx} instead
#       - Update or remove the factories in `app/models/illumina_c/plate_purposes.rb`
#       - Delete this file
#       - Any failing tests are probably safe to remove
class IlluminaC::MxTubePurpose < IlluminaHtp::MxTubePurpose
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
    lt = library_request(tube)
    return lt.asset.plate if lt.present?

    nil
  end
  deprecate stock_plate: 'Stock plate is nebulous and can easily lead to unexpected behaviour'

  def library_request(tube)
    tube.requests_as_target.where_is_a(IlluminaC::Requests::LibraryRequest).first ||
      tube.requests_as_target.where_is_a(Request::Multiplexing).first.asset
          .requests_as_target.where_is_a(IlluminaC::Requests::LibraryRequest).first
  end

  private

  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }
  end
end
