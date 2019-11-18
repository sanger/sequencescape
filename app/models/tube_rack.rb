# frozen_string_literal: true

# A rack that holds tubes
# Tubes are linked via the RackedTubes association
class TubeRack < Labware
  self.sample_partial = 'assets/samples_partials/tube_rack_samples'

  include Barcode::Barcodeable

  has_many :racked_tubes, dependent: :destroy, inverse_of: :tube_rack
  has_many :tubes, through: :racked_tubes

  def human_barcode
    primary_barcode.present? ? primary_barcode.barcode : nil
  end
end
