# frozen_string_literal: true

# A rack that holds tubes
# Tubes are linked via the RackableTubes association
class TubeRack < Labware
  include Barcode::Barcodeable

  has_many :rackable_tubes, dependent: :destroy, inverse_of: :tube_rack
  has_many :tubes, through: :rackable_tubes
end
