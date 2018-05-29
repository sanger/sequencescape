module Aker
  # Phisical container for the biomaterial
  class Container < ApplicationRecord
    STOCK_PLATE_PURPOSE = 'Aker Plate'

    has_many :samples, dependent: :destroy

    belongs_to :asset

    validates :barcode, presence: true, uniqueness: { scope: :address }

    before_save :update_asset!

    def update_asset!
      return @asset if @asset
      labware = find_or_create_asset_by_aker_barcode!
      @asset ||= address ? labware.wells.located_at(address) : labware
    end

    def find_or_create_asset_by_aker_barcode!
      labware = Asset.find_from_barcode(barcode)
      unless labware
        labware = PlatePurpose.find_by(name: STOCK_PLATE_PURPOSE).create!(barcode: barcode)
      end
      labware      
    end

    def as_json(_options = {})
      {
        barcode: barcode,
        address: address
      }.compact
    end

  end
end
