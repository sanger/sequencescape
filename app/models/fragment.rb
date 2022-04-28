# frozen_string_literal: true
# Fragments were used to represent DNA isolated on an agarose gel
# Whey are no-longer actively created, but persist to preserve legacy
# information.
# Data which was initially stores in a serialized hash 'descriptors'
# has been migrated to the custom metadata
class Fragment < Labware
  include SingleReceptacleLabware
end
