# frozen_string_literal: true

# A rack that holds tubes
# Tubes are linked via the RackedTubes association
class TubeRack < Labware
  self.sample_partial = 'assets/samples_partials/tube_rack_samples'

  include Barcode::Barcodeable

  has_many :racked_tubes, dependent: :destroy, inverse_of: :tube_rack
  has_many :tubes, through: :racked_tubes
  has_many :contained_samples, through: :tubes, source: :samples

  # The receptacles within the tubes.
  # While it may be tempting to just name this association :receptacles it intefers
  # badly with the association on the parent class. Specifically, it looks like the
  # dependent on that relationship triggers a destroy action on *this* association,
  # which doesn't handle it well. Ironic considering the dependent action in the parent
  # class is intended to prevent inadvertant destruction of receptacles.
  has_many :tube_receptacles, through: :tubes, source: :receptacle

  LAYOUTS = {
    48 => {
      'rows' => 6,
      'columns' => 8
    },
    96 => {
      'rows' => 8,
      'columns' => 12
    }
  }.freeze

  def human_barcode
    primary_barcode.present? ? primary_barcode.barcode : nil
  end

  # Used to unify interface with TubeRacks. Returns a list of all {Receptacle receptacles}
  # with position information included for aid performance
  def receptacles_with_position
    tube_receptacles.includes(:racked_tube)
  end

  def self.check_if_coordinates_valid(rack_size, list_coordinates)
    output = []

    num_rows = LAYOUTS[rack_size]['rows']
    num_columns = LAYOUTS[rack_size]['columns']
    valid_row_values = generate_valid_row_values(num_rows)
    valid_column_values = (1..num_columns).to_a

    list_coordinates.each do |coordinate|
      row = coordinate[/[A-Za-z]+/].capitalize
      column = coordinate[/[0-9]+/]
      output << (valid_row_values.include?(row) && valid_column_values.include?(column.to_i))
    end
    output
  end

  def self.generate_valid_row_values(num_rows)
    output = []
    count = 1
    ('A'..'Z').each do |letter|
      output << letter if count <= num_rows
      count += 1
    end
    output
  end
end
