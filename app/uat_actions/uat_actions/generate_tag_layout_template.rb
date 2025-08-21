# frozen_string_literal: true

# Will construct a tag layout template from existing tag groups
class UatActions::GenerateTagLayoutTemplate < UatActions
  self.title = 'Generate tag layout template'
  self.description = 'Generates a tag layout template from one or two tag groups.'
  self.category = :auxiliary_data

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
             select_options: -> { TagLayout::DIRECTION_ALGORITHMS },
             options: {
               include_blank: 'Select a direction...'
             }
  form_field :walking_by_algorithm,
             :select,
             label: 'Walking By',
             help: 'Walking by algorithms, will default to TagLayout::WalkWellsOfPlate if left blank',
             select_options: -> { TagLayout::WALKING_ALGORITHMS },
             options: {
               include_blank: 'Select a walking by...'
             }

  validates :name, presence: { message: 'needs a name' }
  validates :tag_group_name, presence: { message: 'needs a choice' }
  validates :direction_algorithm, presence: { message: 'needs a choice' }

  def perform
    report[:name] = name
    return true if existing_tag_layout_template

    walk_algorithm = walking_by_algorithm.presence || 'TagLayout::WalkWellsOfPlate'

    tlt_parameters = {
      name: name,
      tag_group_id: tag_group.id,
      tag2_group_id: tag2_group&.id,
      direction_algorithm: direction_algorithm,
      walking_algorithm: walk_algorithm
    }

    tlt = TagLayoutTemplate.create!(tlt_parameters)
    tlt.save
  end

  private

  def user
    UatActions::StaticRecords.user
  end

  def existing_tag_layout_template
    return @existing_tag_layout_template if defined?(@existing_tag_layout_template)

    @existing_tag_layout_template = TagLayoutTemplate.find_by(name:)
  end

  def tag_group
    return @tag_group if defined?(@tag_group)

    @tag_group = TagGroup.find_by(name: tag_group_name)
  end

  def tag2_group
    return nil if tag2_group_name.blank?
    return @tag2_group if defined?(@tag2_group)

    @tag2_group = TagGroup.find_by(name: tag2_group_name)
  end
end
