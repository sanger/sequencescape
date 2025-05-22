# frozen_string_literal: true

# A rack that holds tubes
# Tubes are linked via the RackedTubes association
class TubeRack < Labware
  include Barcode::Barcodeable
  include Asset::Ownership::Unowned

  self.sample_partial = 'assets/samples_partials/tube_rack_samples'

  has_many :racked_tubes, dependent: :destroy, inverse_of: :tube_rack
  has_many :tubes, through: :racked_tubes
  has_many :contained_samples, through: :tubes, source: :samples
  has_many :contained_aliquots, through: :tube_receptacles, source: :aliquots

  has_many :in_progress_requests, through: :contained_aliquots, source: :request

  # TODO: change to purpose_id
  belongs_to :purpose, class_name: 'TubeRack::Purpose', foreign_key: :plate_purpose_id, inverse_of: :tube_racks

  # The receptacles within the tubes.
  # While it may be tempting to just name this association :receptacles it interferes
  # badly with the association on the parent class. Specifically, it looks like the
  # dependent on that relationship triggers a destroy action on *this* association,
  # which doesn't handle it well. Ironic considering the dependent action in the parent
  # class is intended to prevent inadvertent destruction of receptacles.
  has_many :tube_receptacles, through: :tubes, source: :receptacle

  # Requests comming out out the tubes contained in the rack
  has_many :requests_as_source, through: :tubes
  has_many :requests_as_target, through: :tubes
  has_many :transfer_requests_as_source, through: :tube_receptacles
  has_many :transfer_requests_as_target, through: :tube_receptacles
  has_many :aliquots, through: :tubes

  LAYOUTS = { 48 => { rows: 6, columns: 8 }, 96 => { rows: 8, columns: 12 } }.freeze

  TUBE_RACK_STATES = %w[started qc_complete pending passed failed cancelled mixed empty].freeze

  STATES_TO_FILTER_OUT = %w[cancelled failed].freeze
  STATE_EMPTY = 'empty'
  STATE_MIXED = 'mixed'

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
  # with position information included for aid performance.
  #
  # @return [ActiveRecord::Relation] A relation of tube receptacles with position information.
  def receptacles_with_position
    tube_receptacles.includes(:racked_tube)
  end

  # Returns the number of rows in the tube rack based on its size.
  #
  # @return [Integer] The number of rows in the tube rack.
  def number_of_rows
    LAYOUTS.fetch(size)[:rows]
  end
  alias height number_of_rows

  # Returns the number of columns in the tube rack based on its size.
  #
  # @return [Integer] The number of columns in the tube rack.
  def number_of_columns
    LAYOUTS.fetch(size)[:columns]
  end
  alias width number_of_columns

  # Handles the addition of a comment to the tube rack and its associated submissions and tubes.
  # Adds the comment to the submissions to avoid duplicate comments and also adds the comment to the tubes.
  #
  # @param comment [String] The comment to be added.
  def after_comment_addition(comment)
    # We don't let the tubes handle addition to submissions, as if they
    # all belong to the same submission, we'll get duplicate comments
    comments.add_comment_to_submissions(comment)

    # But we still want to add to the tube anyway, as we may have some
    # tubes that don't have submissions. Or even a mixed rack.
    comments.add_comment_to_tubes(comment)
  end

  # The state of a tube rack is based on the transfer requests in the tubes.
  # If they are all in the same state then it takes that state.
  def state
    # fetch states from ther transfer requests in all racked tubes in the rack.
    unique_states = transfer_requests_as_target.map(&:state).uniq

    return STATE_EMPTY if unique_states.empty?
    return unique_states.first if unique_states.size == 1

    STATES_TO_FILTER_OUT.each do |filter|
      unique_states.delete(filter)
      return unique_states.first if unique_states.one?
    end

    # we still have tubes with a mixed state
    STATE_MIXED
  end
end