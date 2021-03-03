# @deprecated Part of the old pulldown pipeline
# Specialised implementation of the plate purpose for the initial plate types in the Pulldown pipelines:
# WGS Covaris, SC Covaris, ISC Covaris.
# @todo #2396 Remove this class. This will require:
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
#       - Update:
#           seeds/0002_plate_purposes.rb:
#         Remove the seed or update to us standard plate purpose.
class Pulldown::InitialPlatePurpose < PlatePurpose
  # This class is empty and is maintained to prevent us
  # breaking existing database records until they have been
  # migrated to PlatePurpose
end
