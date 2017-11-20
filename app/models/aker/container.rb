module Aker
  class Container < ActiveRecord::Base
    has_many :samples

    validates :barcode, presence: true, uniqueness: true

    def as_json(_options = {})
      {
        barcode: barcode,
        address: address
      }.compact
    end
  end
end
