# frozen_string_literal: true

# A TubeRackStatus stores the status of the creation process of tube racks
class TubeRackStatus < ApplicationRecord
  validates :barcode, presence: true
  validates :status, presence: true

  serialize :messages

  belongs_to :labware

  STATUS_CREATED = 'created'
  STATUS_VALIDATION_FAILED = 'validation failed'

  VALID_STATES = [STATUS_CREATED, STATUS_VALIDATION_FAILED].freeze
end
