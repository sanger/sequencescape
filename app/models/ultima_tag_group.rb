# frozen_string_literal: true

# Ultima data for a tag group in tag_groups, one row per Ultima tag group.
# Ultima sample sheets show the plate number as Barcode_Plate_Num for every
# tag in the group. The plate number is nil when Ultima gives none for the
# tag group; a sample sheet with tags from such a group then leaves the
# Barcode_Plate_Num column out, as Ultima's sample sheet format allows.
class UltimaTagGroup < ApplicationRecord
  belongs_to :tag_group, optional: false

  validates :tag_group_id, uniqueness: true
  # nil when Ultima gives no plate number; the sheet leaves the column out.
  validates :barcode_plate_num,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
end
