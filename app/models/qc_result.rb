# frozen_string_literal: true

# QcResult
# QC results record any measurement, qualitative or quantitative about an asset
# For example, volume/concentration
# Assay type: The protocol/equipment used. Might also indicate the stage of the process.
# Assay version: Allows versioning and comparison of different protocols
# Value: The measurement recorded
# Units: eg. nM, the units in which the measurement was recorded
# Key: The attribute being measured. Eg. Concentration
# qc_assay: Groups together qc results performed at the same time.
class QcResult < ApplicationRecord
  include Api::Messages::QcResultIo::Extensions

  # Set to disable updating well_attributes
  attr_accessor :suppress_updates

  belongs_to :asset, optional: false, class_name: 'Receptacle'
  belongs_to :qc_assay, optional: true

  convert_labware_to_receptacle_for :asset, :target_asset

  has_many :samples, through: :asset, source: :samples
  has_many :studies, through: :asset

  after_create :update_asset, unless: :suppress_updates
  after_commit :broadcast_qc_result, on: %i[create update]

  validates :key, :value, :units, presence: true

  scope :last_qc_result_for, ->(key) { where(key:).order(created_at: :desc, id: :desc).limit(1) }
  scope :order_by_date, -> { order(created_at: :desc) }

  def self.by_key
    order_by_date.group_by { |qc_result| qc_result.key.downcase }
  end

  #
  # Returns a unit object, which allows easy conversion between different scales,
  # as well as performing arithmetic with different measurements.
  # Caution: Raises an exception if the units are unrecognised, or if the value is
  # not a number
  #
  # @return [Unit] A combination of the value and units for the given measurement.
  def unit_value
    # Don't cache to avoid the need to worry about cache invalidation
    Unit.new(value, units)
  end

  def unit_value=(unit_value)
    self.value = unit_value.scalar
    self.units = unit_value.units
  end

  private

  def update_asset
    asset.update_from_qc(self)
  end

  def broadcast_qc_result
    Messenger.new(target: self, template: 'QcResultIo', root: 'qc_result').broadcast
  end
end
