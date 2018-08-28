# frozen_string_literal: true

# QcResult
class QcResult < ApplicationRecord
  include Api::Messages::QcResultIO::Extensions

  # Set to disable updating well_attributes
  attr_accessor :suppress_updates

  belongs_to :asset, required: true
  belongs_to :qc_assay, required: false

  after_create :update_asset, unless: :suppress_updates
  after_commit :broadcast_qc_result, on: [:create, :update]

  validates :key, :value, :units, presence: true

  scope :last_qc_result_for, ->(key) { where(key: key).order(created_at: :desc, id: :desc).limit(1) }
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
    Messenger.new(target: self, template: 'QcResultIO', root: 'qc_result').broadcast
  end
end
