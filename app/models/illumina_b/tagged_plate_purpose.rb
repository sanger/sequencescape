# The initial implementation of the Illumina-B pulldown-like pathway
# uses only two plate purposes. The tagged plate should have the behaviour
# of both the initial plate (ensuring outer requests are started)
# and the library, allowing subsequent requests to be made on the plate.
# This behaviour can be split up later.
class IlluminaB::TaggedPlatePurpose < PlatePurpose
  include PlatePurpose::Initial
  include PlatePurpose::Library
end
