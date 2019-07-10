# frozen_string_literal: true

class TagLayout::DualIndexWalker < TagLayout::Walker
  # Each row and column is essentially duplicated. So our scale
  # is 2 (not four)
  PLATE_SCALE = 2

  def walk_wells
    wells_in_walking_order.includes(:map).each do |well|
      row = well.map.row
      col = well.map.column
      index = direction_helper.tag_index(row, col, PLATE_SCALE, height, width)
      index2 = direction_helper.tag2_index(row, col, PLATE_SCALE, height, width)
      yield(well, index, index2)
    end
  end

  private

  def height
    @height ||= plate.height
  end

  def width
    @width ||= plate.width
  end

  def direction_helper
    tag_layout.direction_algorithm_module
  end
end
