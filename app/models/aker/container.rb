module Aker
  # Phisical container for the biomaterial
  class Container < ApplicationRecord
    has_many :samples, dependent: :destroy

    belongs_to :asset

    validates :barcode, presence: true, uniqueness: { scope: :address }
    validate :not_change_barcode
    validate :not_change_address

    def volume
      asset.get_qc_result_value_for('Volume') || asset.well_attribute.get_current_volume
    end

    def concentration
      asset.get_qc_result_value_for('Concentration') || asset.well_attribute.get_concentration
    end

    def amount
      return (volume.to_f * concentration.to_f).to_s if volume && concentration
      nil
    end

    def not_change_barcode
      errors.add(:barcode, 'Cannot modify barcode') if persisted? && barcode_changed?
    end

    def not_change_address
      errors.add(:address, 'Cannot modify address') if persisted? && address_changed?
    end

    def a_well?
      if asset
        asset.is_a? Well
      else
        !self.class.tube_address?(address)
      end
    end

    def self.tube_address?(address)
      (address =~ /^\d/) || address.nil?
    end

    def as_json(_options = {})
      {
        barcode: barcode,
        address: address
      }.compact
    end
  end
end
