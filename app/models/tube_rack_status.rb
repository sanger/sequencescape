# frozen_string_literal: true

# A TubeRackStatus stores the status of the creation process of tube racks
class TubeRackStatus < ApplicationRecord
  enum :status, { created: 0, validation_failed: 1 }

  validates :barcode, presence: true
  validates :status, presence: true

  serialize :messages, coder: YAML

  belongs_to :labware
end
