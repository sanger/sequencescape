module Aker
  # Phisical container for the biomaterial
  class Container < ApplicationRecord
    has_many :samples, dependent: :destroy

    belongs_to :asset

    validates :barcode, presence: true, uniqueness: { scope: :address }
    validate :not_change_barcode
    validate :not_change_address

    def not_change_barcode
      errors.add(:barcode, 'Cannot modify barcode') if persisted? && barcode_changed?
    end

    def not_change_address
      errors.add(:address, 'Cannot modify address') if persisted? && address_changed?
    end

    def is_a_well?
      if asset
        asset.is_a? Well
      else
        !self.class.is_tube_address?(address)
      end
    end

    def self.is_tube_address?(address)
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
