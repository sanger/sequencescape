# frozen_string_literal: true

# Tags are arranged in quadrants in the case of some 384 well plates.
# Essentially a 96 well plate of tags is transferred onto the same target
# plate four times, such that each cluster of 4 wells contains the same tag.
# Ie. Tag 1 is in wells A1, B1, A2, B2
# In the case of column then row direction algorithms
# Four different tag 2s then get applied to each cluster. These tags are
# laid out in *ROW* order
# ie. A1 => 1, A2 => 2, B1 => 3, B2 => 4
# If the direction is row or column then Tag2 is laid out in the same manner as
# tag 1.
class TagLayout::Quadrants < TagLayout::DualIndexWalker
  self.walking_by = 'quadrants'
end
