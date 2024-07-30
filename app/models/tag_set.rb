# frozen_string_literal: true

class TagSet < ApplicationRecord
  include Uuid::Uuidable

  # Associations
  belongs_to :tag_group, class_name: 'TagGroup', optional: true
  belongs_to :tag2_group, class_name: 'TagGroup', optional: true

  # Constants for indexing strings
  INDEX_SINGLE = 'single'
  INDEX_DUAL = 'dual'
  INDEX_NONE = 'none'

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

  def indexing
    if tag_group && tag2_group
      INDEX_DUAL
    elsif tag_group
      INDEX_SINGLE
    else
      INDEX_NONE
    end
  end

  # Validate that adapter type of tag groups of a tag set are equal
  def validate_adapter_type
    return unless tag_group && tag2_group && tag_group.adapter_type != tag2_group.adapter_type
      errors.add(:base, 'Adapter types of tag groups must be equal')
  end
end
