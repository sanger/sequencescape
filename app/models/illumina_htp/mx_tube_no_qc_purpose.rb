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
class IlluminaHtp::MxTubeNoQcPurpose < IlluminaHtp::MxTubePurpose
  self.state_changer = StateChanger::MxTubeNoQc
end
