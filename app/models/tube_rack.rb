# frozen_string_literal: true

class TubeRack < Labware
  include Barcode::Barcodeable

  has_many :rackable_tubes, dependent: :destroy
  has_many :tubes, through: :rackable_tubes
end
