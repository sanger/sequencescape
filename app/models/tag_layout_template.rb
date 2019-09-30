# This is a layout template for tags.  Think of it as a partially created TagLayout, defining only the tag
# group that will be used and the actual TagLayout implementation that will do the work.
class TagLayoutTemplate < ApplicationRecord
  include Uuid::Uuidable
  include Lot::Template

  attr_writer :enforce_uniqueness

  belongs_to :tag_group, optional: false
  belongs_to :tag2_group, class_name: 'TagGroup'

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :direction_algorithm, presence: true
  validates :walking_algorithm, presence: true

  delegate :direction, to: :direction_algorithm_class
  delegate :walking_by, to: :walking_algorithm_class

  scope :include_tags, -> { includes(tag_group: :tags, tag2_group: :tags) }

  def stamp_to(_)
    # Do Nothing
  end

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    TagLayout.create!(attributes.merge(tag_layout_attributes), &block).tap do |tag_layout|
      record_template_use(tag_layout.plate)
    end
  end

  private

  # By default if not overidden, dual indexed tag template
  # enforce their uniqueness
  # Note we need to use instance_variable_defined? as nil is a perfectly valid value
  def enforce_uniqueness
    instance_variable_defined?('@enforce_uniqueness') ? @enforce_uniqueness : tag2_group.present?
  end

  def direction_algorithm_class
    direction_algorithm.constantize
  end

  def walking_algorithm_class
    walking_algorithm.constantize
  end

  def tag_layout_attributes
    {
      tag_group: tag_group,
      tag2_group: tag2_group,
      direction_algorithm: direction_algorithm,
      walking_algorithm: walking_algorithm
    }
  end

  def record_template_use(plate)
    plate.submissions.each do |submission|
      TagLayout::TemplateSubmission.create!(submission: submission, tag_layout_template: self, enforce_uniqueness: enforce_uniqueness)
    end
  end
end
