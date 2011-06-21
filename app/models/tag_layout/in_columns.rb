# Lays out the tags so that they are column ordered.
class TagLayout::InColumns < TagLayout
  class_inheritable_reader :direction
  write_inheritable_attribute(:direction, 'column')
end
