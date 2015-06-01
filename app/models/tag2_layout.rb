#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
# Lays out the tags in the specified tag group in a particular pattern.
#
# Applies a single tag 2 to the entire plate
class Tag2Layout < ActiveRecord::Base
  include Uuid::Uuidable

  # The user performing the layout
  belongs_to :user
  validates_presence_of :user

  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag
  validates_presence_of :tag

  serialize :substitutions

  belongs_to :plate
  validates_presence_of :plate

  belongs_to :source, :class_name => 'Asset'

  named_scope :include_tag, :include => :tag
  named_scope :include_plate, :include => :plate

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tag2_into_wells, :if => :valid?

  def layout_tag2_into_wells
    plate.wells.include_aliquots.each {|w| w.assign_tag2(tag) }
  end

end
