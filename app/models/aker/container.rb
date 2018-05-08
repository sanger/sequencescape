module Aker
  # Phisical container for the biomaterial
  class Container < ApplicationRecord
    has_many :samples, dependent: :destroy

    validates :barcode, presence: true, uniqueness: { scope: :address }

    def as_json(_options = {})
      {
        barcode: barcode,
        address: address
      }.compact
    end
  end
end
