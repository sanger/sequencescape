# frozen_string_literal: true

class RackableTube < ApplicationRecord
  # TODO:
  # Add dependent action for tube
  belongs_to :tube
  belongs_to :tube_rack
end
