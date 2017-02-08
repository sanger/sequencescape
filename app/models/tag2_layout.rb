# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# Lays out the tags in the specified tag group in a particular pattern.
#
# Applies a single tag 2 to the entire plate
class Tag2Layout < ActiveRecord::Base
  include Uuid::Uuidable

  attr_writer :layout_template
  serialize :target_well_locations
  ##
  # This class provides two benefits
  # 1) We can enforce uniqueness of tag2_layouts/submissions at the database level
  #    This helps avoid potential race conditions (Although they won't be handled
  #    especially elegantly)
  # 2) It provides an easy means of looking up used templates
  class TemplateSubmission < ActiveRecord::Base
    belongs_to :submission
    belongs_to :tag2_layout_template
    validates_presence_of   :tag2_layout_template_id, :submission_id
    validates_uniqueness_of :tag2_layout_template_id, scope: :submission_id
  end

  # The user performing the layout
  belongs_to :user
  validates_presence_of :user

  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag
  validates_presence_of :tag

  serialize :substitutions

  belongs_to :plate
  validates_presence_of :plate

  belongs_to :source, class_name: 'Asset'

  scope :include_tag, ->() { includes(:tag) }
  scope :include_plate, ->() { includes(:plate) }

  before_create :record_template_use
  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tag2_into_wells, if: :valid?

  def record_template_use
    plate.submissions.each do |submission|
      TemplateSubmission.create!(submission: submission, tag2_layout_template: layout_template)
    end
  end

  def layout_tag2_into_wells
    applicable_wells = plate.wells.include_aliquots
    if attributes['target_well_locations']
      applicable_wells = applicable_wells.select { |w| attributes['target_well_locations'].include?(w.map.description) }
    end
    applicable_wells.each { |w| w.assign_tag2(tag) }
  end

  def layout_template
    @layout_template || Tag2LayoutTemplate.find_by(tag_id: tag)
  end
end
