module Aker
  class Container < ActiveRecord::Base
    has_many :samples

    validates :barcode, presence: true, uniqueness: true
  end
end
