#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.
# This is a layout template for tags.  Think of it as a partially created TagLayout, defining only the tag
# group that will be used and the actual TagLayout implementation that will do the work.
class TagLayoutTemplate < ActiveRecord::Base
  include Uuid::Uuidable
  include Lot::Template

  belongs_to :tag_group
  validates_presence_of :tag_group

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :direction_algorithm
  validates_presence_of :walking_algorithm

  delegate :direction, :to => :direction_algorithm_class
  delegate :walking_by, :to => :walking_algorithm_class

  scope :include_tags, -> { includes({ :tag_group => :tags }) }

  def stamp_to(_)
    # Do Nothing
  end

  def direction_algorithm_class
    direction_algorithm.constantize
  end
  private :direction_algorithm_class

  def walking_algorithm_class
    walking_algorithm.constantize
  end
  private :walking_algorithm_class

  def tag_layout_attributes
    {
      :tag_group => tag_group,
      :direction_algorithm => direction_algorithm,
      :walking_algorithm => walking_algorithm
    }
  end
  private :tag_layout_attributes

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    TagLayout.create!(attributes.merge(tag_layout_attributes), &block)
  end
end
