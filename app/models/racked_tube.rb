# frozen_string_literal: true

# Links a tube to a tube rack.
# 'Coordinate' field specifies the location it is within the rack (e.g. 'A1')
class RackedTube < ApplicationRecord
  belongs_to :tube
  belongs_to :tube_rack

  scope :in_column_major_order, -> { order('coordinate ASC') }
end
