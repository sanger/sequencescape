
class AliquotIndex < ApplicationRecord
  belongs_to :aliquot
  belongs_to :lane

  validates_presence_of :aliquot
  validates_presence_of :lane
  validates_numericality_of :aliquot_index, only_integer: true, greater_than: 0, less_than_or_equal_to: 9999, allow_blank?: false
end
