# frozen_string_literal: true

# Will construct a tag layout template from existing tag groups
class UatActions::GenerateTagSet < UatActions
  self.title = 'Generate tag set'
  self.description = 'Generates a set.'
  self.category = :auxiliary_data

  form_field :tag_group_name,
             :select,
             label: 'Tag Group',
             help: 'Select tag group 1 for the template',
             select_options: -> { TagGroup.visible.pluck(:name) },
             options: {
               include_blank: 'Select tag group...'
             }
  form_field :tag2_group_name,
             :select,
             label: 'Tag2 Group',
             help: 'Select tag group 2 for the template',
             select_options: -> { TagGroup.visible.pluck(:name) },
             options: {
               include_blank: 'Select tag 2 group...'
             }

  validates :name, presence: { message: 'needs a name' }
  validates :tag_group_name, presence: { message: 'needs a choice' }

  def perform
    report[:name] = name
    return true if existing_tag_set

    ts_parameters = {
      name: name,
      tag_group_id: tag_group.id,
      tag2_group_id: tag2_group&.id,
    }

    tlt = TagSet.create!(ts_parameters)
    tlt.save
  end

  private

  def user
    UatActions::StaticRecords.user
  end

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
end
