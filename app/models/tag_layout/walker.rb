# frozen_string_literal: true

# A walker passes over the wells of a plate and yeilds the
# appropriate tag index
class TagLayout::Walker
  attr_reader :tag_layout

  class_attribute :walking_by

  delegate_missing_to :tag_layout

  def initialize(tag_layout)
    @tag_layout = tag_layout
  end

  # We don't actually implement the main behaviour here.
  # If you add a new walker, this is where you add your new behaviour
  def walk_wells
    raise StandardError, "#{self.class.name} should implement #walk_wells"
  end

  # Over-ridden in the as group by plate module to allow the application of multiple tags.
  def apply_tags(well, tag, tag2)
    well.attach_tags(tag, tag2) unless well.aliquots.empty?
  end
end
