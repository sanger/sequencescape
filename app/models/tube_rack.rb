# frozen_string_literal: true

# A rack that holds tubes
# Tubes are linked via the RackedTubes association
class TubeRack < Labware
  include Barcode::Barcodeable

  self.sample_partial = 'assets/samples_partials/tube_rack_samples'

  has_many :racked_tubes, dependent: :destroy, inverse_of: :tube_rack
  has_many :tubes, through: :racked_tubes
  has_many :contained_samples, through: :tubes, source: :samples

  # The receptacles within the tubes.
  # While it may be tempting to just name this association :receptacles it interferes
  # badly with the association on the parent class. Specifically, it looks like the
  # dependent on that relationship triggers a destroy action on *this* association,
  # which doesn't handle it well. Ironic considering the dependent action in the parent
  # class is intended to prevent inadvertent destruction of receptacles.
  has_many :tube_receptacles, through: :tubes, source: :receptacle

  # Requests comming out out the tubes contained in the rack
  has_many :requests_as_source, through: :tubes
  has_many :aliquots, through: :tubes

  LAYOUTS = { 48 => { rows: 6, columns: 8 }, 96 => { rows: 8, columns: 12 } }.freeze

  validates :size, inclusion: { in: LAYOUTS.keys }

  def self.invalid_coordinates(rack_size, list_coordinates)
    num_rows = LAYOUTS.fetch(rack_size)[:rows]
    num_columns = LAYOUTS.fetch(rack_size)[:columns]
    valid_row_values = generate_valid_row_values(num_rows)
    valid_column_values = (1..num_columns)

    list_coordinates.reject do |coordinate|
      row = coordinate[/[A-Za-z]+/].capitalize
      column = coordinate[/[0-9]+/]
      valid_row_values.include?(row) && valid_column_values.cover?(column.to_i)
    end
  end

  def self.generate_valid_row_values(num_rows)
    ('A'..).first(num_rows)
  end

  # Comments are proxied as they need to collect comments from
  # various different associations, not just the tubes
  def comments
    @comments ||= CommentsProxy::TubeRack.new(self)
  end

  # Used to unify interface with TubeRacks. Returns a list of all {Receptacle receptacles}
  # with position information included for aid performance
  def receptacles_with_position
    tube_receptacles.includes(:racked_tube)
  end

  def number_of_rows
    LAYOUTS.fetch(size)[:rows]
  end
  alias height number_of_rows

  def number_of_columns
    LAYOUTS.fetch(size)[:columns]
  end
  alias width number_of_columns

  def after_comment_addition(comment)
    # We don't let the tubes handle addition to submissions, as if they
    # all belong to the same submission, we'll get duplicate comments
    comments.add_comment_to_submissions(comment)

    # But we still want to add to the tube anyway, as we may have some
    # tubes that don't have submissions. Or even a mixed rack.
    comments.add_comment_to_tubes(comment)
  end
end
