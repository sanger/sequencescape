# frozen_string_literal: true

class TubeRack < ApplicationRecord
  has_many :rackable_tubes, dependent: :destroy
  has_many :tubes, through: :rackable_tubes
end
