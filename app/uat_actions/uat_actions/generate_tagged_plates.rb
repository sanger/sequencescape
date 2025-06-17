# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::GenerateTaggedPlates < UatActions::GeneratePlates
  # These walking algorithms have dependencies on submission and do
  # not make sense here.
  EXCLUDED_WALKING = ['wells in pools', 'manual by pool'].freeze

  self.title = 'Generate tagged plates'

  # The description displays on the list of UAT actions to provide additional information
  self.description =
    'Generates a plate of tagged samples. For plates of tags for use in Limber see "Generate Tag plates".'
  self.category = :auxiliary_data

  # @see UatActions::GeneratePlates for other fields
  form_field :tag_group_name,
             :select,
             label: 'i7 (tag) Tag group',
             help:
               'Select the tag group to use for the i7 tag. ' \
               'This tag is usually set both for single and dual ' \
               'indexing.',
             select_options: -> { TagGroup.visible.alphabetical.pluck(:name) }
  form_field :tag2_group_name,
             :select,
             label: 'i5 (tag2) Tag group',
             help:
               'Select the tag group to use for the i7 tag. ' \
               'Set to \'Untagged\' for single indexed samples.',
             select_options: -> { TagGroup.visible.alphabetical.pluck(:name) },
             options: {
               include_blank: 'Untagged'
             }
  form_field :direction,
             :select,
             label: 'Tag direction',
             help:
               'The order in which tags will be laid out on the plate. ' \
               'Most commonly \'column\'.',
             select_options: -> { TagLayout::DIRECTION_ALGORITHMS.keys }
  form_field :walking_by,
             :select,
             label: 'Tag layout pattern',
             help:
               'Select the algorithm used to layout tags. The most common ' \
               'are: \'wells of plate\' which uses a fixed tag layout ' \
               'across the plate. \'manual by plate\' which selects tags ' \
               'for each occupied well in turn.',
             # NOTE: We filter out the 'by pool' options here as they are
             # driven by submission information
             select_options: -> { TagLayout::WALKING_ALGORITHMS.keys - EXCLUDED_WALKING }

  validates :direction, inclusion: { in: TagLayout::DIRECTION_ALGORITHMS.keys }, presence: true
  validates :walking_by, inclusion: { in: TagLayout::WALKING_ALGORITHMS.keys - EXCLUDED_WALKING }, presence: true
  validates :tag_group_name, presence: true
  validates :tag_group, presence: { message: 'could not be found' }, if: :tag_group_name
  validates :tag2_group, presence: { message: 'could not be found' }, if: :tag2_group_name?

  def self.default
    new(
      plate_count: 1,
      well_count: 96,
      study_name: UatActions::StaticRecords.study.name,
      plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
      well_layout: 'Column',
      direction: 'column',
      walking_by: 'wells of plate'
    )
  end

  def perform
    super { |plate| TagLayout.create!(user:, plate:, direction:, walking_by:, tag_group:, tag2_group:) }
  end

  private

  def tag2_group_name?
    tag2_group_name.present?
  end

  def user
    UatActions::StaticRecords.user
  end

  def tag_group
    @tag_group ||= TagGroup.find_by(name: tag_group_name)
  end

  def tag2_group
    @tag2_group ||= TagGroup.find_by(name: tag2_group_name) if tag2_group_name.present?
  end
end
