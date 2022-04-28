# frozen_string_literal: true
# An AliquotIndex is generated for all {Aliquot aliquots} in a {Lane} when the
# {Batch} is released. It gives each aliquot in the {Lane} a unique index which
# can get presented to NPG.
#
# @note Aliquot index replaces the role previously played by the tag map_id. It
# was added when dual indexing was added to ensure NPG still had a single identifier.
#
# @see AliquotIndexer The AliquotIndexer generates aliquot indexes for a given {Lane}
class AliquotIndex < ApplicationRecord
  belongs_to :aliquot
  belongs_to :lane

  validates :aliquot, presence: true
  validates :lane, presence: true
  validates :aliquot_index,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 9999,
              allow_blank?: false
            }
end
