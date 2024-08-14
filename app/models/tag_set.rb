# frozen_string_literal: true

# Links together two related tag groups - i7 and i5 - to represent a dual index tag set
# It can also be used to represent single index tag sets
# Background explained in Y24-170 (https://github.com/sanger/sequencescape/issues/4160)
class TagSet < ApplicationRecord
  # For dual index tags, tag_group is i7 oligos and tag2_group is i5 oligos
  belongs_to :tag_group, class_name: 'TagGroup', optional: false
  belongs_to :tag2_group, class_name: 'TagGroup', optional: true

  # We can assume adapter_type is the same for both tag groups
  # But tag2_group may not be present so we delegate to tag_group
  delegate :adapter_type, to: :tag_group

  validates :name, presence: true, uniqueness: true
  validate :tag_group_adapter_types_must_match

  # Dynamic method to determine the visibility of a tag_set based on the visibility of its tag_groups
  def visible
    tag_group.visible && (tag2_group.nil? || tag2_group.visible)
  end

  # Method to determine that both tag groups have the same adapter type
  def tag_group_adapter_types_must_match
    return unless tag2_group && tag_group.adapter_type != tag2_group.adapter_type
    errors.add(:tag_group, 'Adapter types of tag groups must match')
  end

  def tag_group_name=(name)
    self.tag_group = TagGroup.find_by!(name: name)
  end

  def tag2_group_name=(name)
    self.tag2_group = TagGroup.find_by!(name: name)
  end
end
