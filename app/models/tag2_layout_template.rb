# Tag 2 Layouts apply a single tag to the entire plate
class Tag2LayoutTemplate < ApplicationRecord
  include Uuid::Uuidable
  include Lot::Template

  belongs_to :tag
  validates :tag, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :include_tag, ->() { includes(:tag) }

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    Tag2Layout.create!(attributes.merge(default_attributes), &block).tap do |t2layout|
      record_template_use(t2layout.plate)
    end
  end

  def stamp_to(_)
    # Do Nothing
  end

  private

  def record_template_use(plate)
    plate.submissions.each do |submission|
      Tag2Layout::TemplateSubmission.create!(submission: submission, tag2_layout_template: self)
    end
  end

  def default_attributes
    { tag: tag }
  end
end
