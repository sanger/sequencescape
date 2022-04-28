# frozen_string_literal: true
class TagLayout::WalkWellsOfPlate < TagLayout::Walker # rubocop:todo Style/Documentation
  self.walking_by = 'wells of plate'

  def walk_wells
    wells_in_walking_order.each_with_index { |well, index| yield(well, index) unless well.nil? }
  end
end
