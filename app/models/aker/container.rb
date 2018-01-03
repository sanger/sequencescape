module Aker
  class Container < ApplicationRecord
    has_many :samples, dependent: :destroy

    validates :barcode, presence: true, uniqueness: true

    def as_json(_options = {})
      {
        barcode: barcode,
        address: address
      }.compact
    end
  end
end
