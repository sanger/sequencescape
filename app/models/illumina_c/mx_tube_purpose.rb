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
  def stock_plate(tube)
    lt = library_request(tube)
    return lt.asset.plate if lt.present?

    nil
  end

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
