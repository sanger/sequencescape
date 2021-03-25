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
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaHtp::DownstreamPlatePurpose < PlatePurpose
end
