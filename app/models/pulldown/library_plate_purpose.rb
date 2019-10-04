# @deprecated Part of the old pulldown pipeline
# Tag plate in the old pulldown pipleines. Applies library information to the aliquots.
# Used by:
#
# - WGS lib PCR
# - SC cap lib PCR
# - ISC lib PCR
#
# @todo #2396 Remove this class. This will require:
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           seeds/0002_plate_purposes.rb:
#         Remove the seed or update to us standard plate purpose.
class Pulldown::LibraryPlatePurpose < PlatePurpose
  include PlatePurpose::Library
end
