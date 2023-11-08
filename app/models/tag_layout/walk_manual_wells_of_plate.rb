# frozen_string_literal: true
class TagLayout::WalkManualWellsOfPlate < TagLayout::Walker
  self.walking_by = 'wells of plate'

  def walk_wells
    wells_in_walking_order.with_aliquots.each_with_index { |well, index| yield(well, index) unless well.nil? }
  end
end
