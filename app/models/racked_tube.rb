# frozen_string_literal: true

# Links a tube to a tube rack.
# 'Coordinate' field specifies the location it is within the rack (e.g. 'A1')
class RackedTube < ApplicationRecord
  belongs_to :tube
  belongs_to :tube_rack
  has_one :receptacle, through: :tube, source: :receptacle

  # TODO: This sort will fail and will perform an alphanumeric sort, returning
  # eg. A1, A10, A11, A12, A2 ...
  scope :in_column_major_order, -> { order(:coordinate) }
end
