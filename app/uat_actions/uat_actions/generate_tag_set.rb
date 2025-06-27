# frozen_string_literal: true

# This UAT action generates a tag set from one or two tag groups.
class UatActions::GenerateTagSet < UatActions
  self.title = 'Generate tag set'
  self.description = 'Generates a tag set from one or two tag groups.'
  self.category = :auxiliary_data

  ERROR_TAG_GROUP_DOES_NOT_EXIST = "Tag group '%s' does not exist."
  ERROR_TAG2_GROUP_DOES_NOT_EXIST = "Tag2 group '%s' does not exist."

  form_field :name,
             :text_field,
             label: 'Tag Set Name',
             help: 'It will not create a tag set with a name that already exists.'
  form_field :tag_group_name,
             :select,
             label: 'Tag Group',
             help: 'Select tag group 1 for the tag set',
             select_options: -> { TagGroup.visible.pluck(:name) },
             options: {
               include_blank: 'Select tag group...'
             }
  form_field :tag2_group_name,
             :select,
             label: 'Tag2 Group',
             help: 'Select tag group 2 for the tag set',
             select_options: -> { TagGroup.visible.pluck(:name) },
             options: {
               include_blank: 'Select tag 2 group...'
             }

  validates :name, presence: true
  validates :tag_group_name, presence: true
  validate :validate_tag_group_exists
  validate :validate_tag2_group_exists

  # Creates a new tag set if it does not already exist. The report is populated
  # with tag set name, tag group name, and tag2 group name.
  # @return [Boolean] true if the tag set is created or already exists.
  def perform
    TagSet.create!(name:, tag_group_name:, tag2_group_name:) if tag_set.blank?
    report.merge!({ name:, tag_group_name:, tag2_group_name: })
    true
  end

  private

  # Validates that the tag group exists for the selected tag group name.
  # @return [void]
  def validate_tag_group_exists
    return if tag_group.present?

    message = format(ERROR_TAG_GROUP_DOES_NOT_EXIST, tag_group_name)
    errors.add(:tag2_group_name, message)
  end

  # Validates that the tag2 group exists if tag2 group name is provided.
  # @return [void]
  def validate_tag2_group_exists
    return if tag2_group_name.blank?
    return if tag2_group.present?

    message = format(ERROR_TAG2_GROUP_DOES_NOT_EXIST, tag2_group_name)
    errors.add(:tag2_group_name, message)
  end

  # Returns the tag set if it exists, otherwise returns nil.
  # @return [TagSet, nil] tag set or nil if not found.
  def tag_set
    @tag_set ||= TagSet.find_by(name:) if name.present?
  end

  # The tag group with the given name, or nil if not present.
  # @return [TagGroup, nil] tag group or nil if not found.
  def tag_group
    @tag_group ||= TagGroup.find_by(name: tag_group_name) if tag_group_name.present?
  end

  # The tag2 group with the given name, or nil if not present.
  # @return [TagGroup, nil] tag2 group or nil if not found.
  def tag2_group
    @tag2_group ||= TagGroup.find_by(name: tag2_group_name) if tag2_group_name.present?
  end
end
