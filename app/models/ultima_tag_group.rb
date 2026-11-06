# frozen_string_literal: true

# Ultima data for a tag group in tag_groups, one row per Ultima tag group.
# Ultima sample sheets show the plate number as Barcode_Plate_Num for every
# tag in the group.
class UltimaTagGroup < ApplicationRecord
  belongs_to :tag_group, optional: false

  validates :tag_group_id, uniqueness: true
  validates :barcode_plate_num,
            numericality: { only_integer: true, greater_than: 0 }
end
