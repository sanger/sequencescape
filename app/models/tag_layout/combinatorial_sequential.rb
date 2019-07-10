# frozen_string_literal: true

# Handles arbitrary layouts of two tags (i7 and i5) based on the direction
# algorithm.
class TagLayout::CombinatorialSequential < TagLayout::DualIndexWalker
  self.walking_by = 'combinatorial sequential'
end
