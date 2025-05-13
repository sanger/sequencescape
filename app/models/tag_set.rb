# frozen_string_literal: true

# Links together two related tag groups - i7 and i5 - to represent a dual index tag set
# It can also be used to represent single index tag sets
# Background explained in Y24-170 (https://github.com/sanger/sequencescape/issues/4160)
class TagSet < ApplicationRecord
  include Uuid::Uuidable
  # For dual index tags, tag_group is i7 oligos and tag2_group is i5 oligos
  belongs_to :tag_group, class_name: 'TagGroup', optional: false

  # In order to support a unified access to dual and single index sets,
  # it allows tag2_group to be null.
  belongs_to :tag2_group, class_name: 'TagGroup', optional: true

  # We can assume adapter_type is the same for both tag groups
  # But tag2_group may not be present so we delegate to tag_group
  delegate :adapter_type, to: :tag_group

  validates :name, presence: true, uniqueness: true
  validate :tag_group_adapter_types_must_match

  scope :dual_index, -> { where.not(tag2_group: nil) }

  # This scope retrieves tag sets that are visible.
  # - If `tag_group` is present and visible, the tag set is included.
  # - If `tag2_group` is present and visible, the tag set is included.
  # - If `tag2_group` is not present, the tag set is included.
  # - If `tag2_group` is present but not visible, the tag set is excluded.
  scope :visible,
        -> do
          joins(:tag_group)
            .joins('LEFT JOIN tag_groups AS tag2_groups ON tag_sets.tag2_group_id = tag2_groups.id')
            .where(tag_groups: { visible: true })
            .where('tag2_groups.id IS NULL OR tag2_groups.visible = ?', true)
        end

  # The scoping retrieves the visible tag sets and makes sure they are dual index.
  scope :visible_dual_index, -> { dual_index.visible }

  scope :by_adapter_type, ->(adapter_type_name) { joins(:tag_group).merge(TagGroup.by_adapter_type(adapter_type_name)) }
  scope :single_index, -> { where(tag2_group: nil) }

  scope :visible_single_index, -> { single_index.visible }

  # Define the scope that combines visible_single_index and chromium tag_group
  scope :visible_single_index_chromium, -> { visible_single_index.joins(:tag_group).merge(TagGroup.chromium) }

  # Dynamic method to determine the visibility of a tag_set based on the visibility of its tag_groups
  # TagSet has a method to check if itself is visible by checking
  # the visibility of both tag_group and (if not null) tag2_group.
  def visible
    tag_group.visible && (tag2_group.nil? || tag2_group.visible)
  end

  # Method to determine that both tag groups have the same adapter type
  def tag_group_adapter_types_must_match
    return unless tag2_group && tag_group.adapter_type != tag2_group.adapter_type
    errors.add(:tag_group, 'Adapter types of tag groups must match')
  end

  def tag_group_name=(name)
    self.tag_group = TagGroup.find_by!(name:)
  end

  def tag2_group_name=(name)
    self.tag2_group = TagGroup.find_by!(name:)
  end
end
