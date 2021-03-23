# Purpose for the {MultiplexedLibraryTube} at the end of the Illumina C pipeline
# The only purpose using this is 'ILC Lib Pool Norm'
#
# @deprecated The pipleine associated with this purpose is no longer used
#
# @todo #2396 Remove this class. This will require:
#
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaC::MxTubePurpose < IlluminaHtp::MxTubePurpose
end
