# frozen_string_literal: true

# Links a tube to a tube rack.
# Coordinates specifies the location it is within the rack.
class RackedTube < ApplicationRecord
  belongs_to :tube
  belongs_to :tube_rack
end
