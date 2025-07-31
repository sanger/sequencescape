# frozen_string_literal: true
# Lays out the tags in the specified tag group in a particular pattern.
#
# Applies a single tag 2 to the entire plate
class Tag2Layout < ApplicationRecord
  include Uuid::Uuidable

  serialize :target_well_locations, coder: YAML

  ##
  # This class provides two benefits
  # 1) We can enforce uniqueness of tag2_layouts/submissions at the database level
  #    This helps avoid potential race conditions (Although they won't be handled
  #    especially elegantly)
  # 2) It provides an easy means of looking up used templates
  class TemplateSubmission < ApplicationRecord
    belongs_to :submission
    belongs_to :tag2_layout_template
    validates :tag2_layout_template_id, :submission_id, presence: true
    validates :tag2_layout_template_id, uniqueness: { scope: :submission_id }
  end

  # The user performing the layout
  belongs_to :user
  validates :user, presence: true

  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag
  validates :tag, presence: true

  serialize :substitutions, coder: YAML

  belongs_to :plate
  validates :plate, presence: true

  belongs_to :source, class_name: 'Labware'

  scope :include_tag, -> { includes(:tag) }
  scope :include_plate, -> { includes(:plate) }

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tag2_into_wells, if: :valid?

  def applicable_wells
    if attributes['target_well_locations']
      plate.wells.located_at(attributes['target_well_locations']).include_aliquots
    else
      plate.wells.include_aliquots
    end
  end

  def layout_tag2_into_wells
    applicable_wells.each do |well|
      well.assign_tag2(tag)
      well.set_as_library
    end
  end
end
