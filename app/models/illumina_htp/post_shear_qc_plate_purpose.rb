# @deprecated Part of the old Illumina-B Lims pipelines
# QC Plate purpose which delegates its state back up to its parent. Used by:
#
# - Post Shear QC
#
# @todo #2396 Remove this class. This will require:
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaHtp::PostShearQcPlatePurpose < PlatePurpose
  # This class is empty and is maintained to prevent us
  # breaking existing database records until they have been
  # migrated to PlatePurpose
end
