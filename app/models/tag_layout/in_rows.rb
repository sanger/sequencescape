# Lays out the tags so that they are row ordered.
class TagLayout::InRows < TagLayout
  class_inheritable_reader :direction
  write_inheritable_attribute(:direction, 'row')
end
