# frozen_string_literal: true

# Will construct a tag layout template from existing tag groups
class UatActions::GenerateTagLayoutTemplate < UatActions
  self.title = 'Generate Tag Layout Template'
  self.description = 'Generates a tag layout template from one or two tag groups.'

  form_field :name,
             :text_field,
             label: 'Tag Layout Template Name',
             help: 'It will not create a tag layout template with a name that already exists.'
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
  form_field :direction_algorithm,
             :select,
             label: 'Direction',
             help: 'Direction the tags are laid out by',
             select_options: -> { TagLayoutTemplatesController::DIRECTIONS },
             options: {
               include_blank: 'Select a direction...'
             }

  validates :name, presence: { message: 'needs a name' }
  validates :tag_group_name, presence: { message: 'needs a choice' }
  validates :direction_algorithm, presence: { message: 'needs a choice' }

  def perform
    report[:name] = name
    return true if existing_tag_layout_template

    tlt_parameters = {
      name: name,
      tag_group_id: tag_group.id,
      tag2_group_id: tag2_group&.id,
      direction_algorithm: direction_algorithm,
      walking_algorithm: 'TagLayout::WalkWellsOfPlate'
    }

    tlt = TagLayoutTemplate.create!(tlt_parameters)
    tlt.save
  end

  private

  def user
    UatActions::StaticRecords.user
  end

  def existing_tag_layout_template
    @existing_tag_layout_template ||= TagLayoutTemplate.find_by(name: name)
  end

  def tag_group
    @tag_group ||= TagGroup.find_by(name: tag_group_name)
  end

  def tag2_group
    return nil if tag2_group_name.blank?

    @tag2_group ||= TagGroup.find_by(name: tag2_group_name)
  end
end
