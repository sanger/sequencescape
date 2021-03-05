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
# @deprecated While this class was actively used, its parent class IlluminaHtp::MxTubePurpose
#             was not. The original behaviour of this class has been move out into the
#             parent, allowing us to use the better named parent class.
#
# @todo #2396 Remove this class. This will require:
#
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaHtp::MxTubeNoQcPurpose < IlluminaHtp::MxTubePurpose
end
