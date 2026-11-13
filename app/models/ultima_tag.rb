# frozen_string_literal: true

# Ultima data for a tag in tags, one row per tag in an Ultima tag group.
# Ultima sample sheets show the Z number as Index_Barcode_Num and the plate
# well as Barcode_Plate_Well.
class UltimaTag < ApplicationRecord
  # Matches "Z" followed by exactly four digits, e.g. Z0001, Z5048.
  INDEX_BARCODE_NUM_FORMAT = /\AZ\d{4}\z/

  belongs_to :tag, optional: false

  alias_attribute :z_index, :index_barcode_num

  validates :tag_id, uniqueness: true
  validates :index_barcode_num,
            presence: true,
            format: { with: INDEX_BARCODE_NUM_FORMAT, allow_blank: true }
  validates :barcode_plate_well, presence: true
end
