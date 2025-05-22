# frozen_string_literal: true
# This is a layout template for tags.  Think of it as a partially created TagLayout, defining only the tag
# group that will be used and the actual TagLayout implementation that will do the work.
class TagLayoutTemplate < ApplicationRecord
  include Uuid::Uuidable
  include Lot::Template

  belongs_to :tag_group, optional: false
  belongs_to :tag2_group, class_name: 'TagGroup'

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :direction_algorithm, presence: true
  validates :walking_algorithm, presence: true

  delegate :direction, to: :direction_algorithm_class
  delegate :walking_by, to: :walking_algorithm_class

  scope :include_tags, -> { includes(tag_group: :tags, tag2_group: :tags) }
  scope :enabled_only, -> { where('enabled = true') }

  def stamp_to(_)
    # Do Nothing
  end

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &)
    new_tag_layout_attributes = attributes.except(:enforce_uniqueness).merge(tag_layout_attributes)

    # By default if not overridden, dual indexed tag template enforce their uniqueness
    # We use fetch here, as both nil and false are expected values
    enforce_uniqueness = attributes.fetch(:enforce_uniqueness, tag2_group.present?)
    TagLayout
      .create!(new_tag_layout_attributes, &)
      .tap { |tag_layout| record_template_use(tag_layout.plate, enforce_uniqueness) }
  end

  def tag_group_name=(name)
    self.tag_group = TagGroup.find_by!(name:)
  end

  def tag2_group_name=(name)
    self.tag2_group = TagGroup.find_by!(name:)
  end

  def record_template_use(plate, enforce_uniqueness)
    plate.submissions.each do |submission|
      TagLayout::TemplateSubmission.create!(
        submission: submission,
        tag_layout_template: self,
        enforce_uniqueness: enforce_uniqueness
      )
    end
  end

  private

  def direction_algorithm_class
    direction_algorithm.constantize
  end

  def walking_algorithm_class
    walking_algorithm.constantize
  end

  def tag_layout_attributes
    { tag_group:, tag2_group:, direction_algorithm:, walking_algorithm: }
  end
end
