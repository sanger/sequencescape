# frozen_string_literal: true

require './lib/oligo_enumerator'

# Will construct plates with well_count wells filled with samples
class UatActions::GenerateTagSet < UatActions
  self.title = 'Generate tag set'

  # The description displays on the list of UAT actions to provide additional information
  self.description = 'Generates a tag set for the specified tag groups.'
  self.category = :auxiliary_data

  # Form fields
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

  validates :name, presence: { message: 'needs a name' }
  validates :tag_group_name, presence: { message: 'needs a choice' }
  validate :tag_groups_must_be_different
  #
  # [perform description]
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    # Called by the controller once the form is filled in. Add your actual actions here.
    # All the form fields are accessible as simple attributes.
    # Return true if everything works
    report[:name] = name
    return true if existing_tag_set

    tag_set = TagSet.create!(name: name, tag_group_id: tag_group.id, tag2_group_id: tag2_group&.id)
    tag_set.save
  end

  private

  # Any helper methods
  #
  def existing_tag_set
    @existing_tag_set ||= TagSet.find_by(name:)
  end

  def tag_group
    @tag_group ||= TagGroup.find_by(name: tag_group_name)
  end

  def tag2_group
    return nil if tag2_group_name.blank?

    @tag2_group ||= TagGroup.find_by(name: tag2_group_name)
  end

  def tag_groups_must_be_different
    return unless tag_group.present? && tag2_group.present? && tag_group.name == tag2_group.name

    errors.add(:tag2_group_name, 'must be different from Tag Group name')
  end

  #
  # Returns the uat user
  #
  # @return [User] The UAT user can be used in any places where a user is expected.
  def user
    UatActions::StaticRecords.user
  end
end
