# frozen_string_literal: true

class TagSet < ApplicationRecord
  include Uuid::Uuidable
  include SharedBehaviour::Named

  # Associations
  belongs_to :tag_group, class_name: 'TagGroup', optional: false
  belongs_to :tag2_group, class_name: 'TagGroup', optional: true

  # Validations
  validates :name, presence: true, uniqueness: true
  validate :validate_adapter_type

  # Returns the first adapter type of its tag groups
  def adapter_type
    tag_group&.adapter_type
  end

  # Returns visibility for a tag set by checking the visibility of its tag groups
  def visible?
    tag_group&.visible? && (tag2_group.nil? || tag2_group.visible?)
  end

  # Validate that adapter type of tag groups of a tag set are equal
  def validate_adapter_type
    return unless tag_group && tag2_group && tag_group.adapter_type != tag2_group.adapter_type
    errors.add(:base, 'Adapter types of tag groups must be equal')
  end

  def tag_group_name=(name)
    self.tag_group = TagGroup.find_by!(name: name)
  end

  def tag2_group_name=(name)
    self.tag2_group = TagGroup.find_by!(name: name)
  end
end
