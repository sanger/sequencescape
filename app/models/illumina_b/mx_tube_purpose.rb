# @deprecated Used by 'ILB_STD_MX' part of old Illumina-B Pipeline app
# @todo #2396 Remove this class. This will involve:
#
#  - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#     Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#     from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaB::MxTubePurpose < Tube::StandardMx
  # This class is empty and is maintained to prevent us
  # breaking existing database records until they have been
  # migrated to Tube::StandardMx
end
