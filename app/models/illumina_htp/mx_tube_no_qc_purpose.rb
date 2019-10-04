# Purposes of this class represent multiplexed library tubes in the high-throughput
# pipeline. These tubes represent the cleaned-up normalized libraries at the end
# of the process that can pass directly into a {SequencingPipeline}.
# Most Limber pipelines finish with a tube purpose of this class.
#
# State changes on these tubes will automatically update the requests into the tubes
#
# THe main difference of this class over the parent is that it passes the library
# creation requests on 'pass' not 'qc_complete'
#
# @note Most current activity is on subclasses of this purpose, especially IlluminaHtp::MxTubeNoQcPurpose
#       As of 2019-10-01 only used directly by 'Lib Pool Norm' and 'Lib Pool SS-XP-Norm' which haven't been
#       used since 2017-04-28 14:16:03 +0100
class IlluminaHtp::MxTubeNoQcPurpose < IlluminaHtp::MxTubePurpose
  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }
  end
  private :mappings
end
