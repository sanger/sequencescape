# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# Tag 2 Layouts apply a single tag to the entire plate
class Tag2LayoutTemplate < ActiveRecord::Base
  include Uuid::Uuidable
  include Lot::Template

  belongs_to :tag
  validates_presence_of :tag

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :include_tag, ->() { includes(:tag) }

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    Tag2Layout.create!(attributes.merge(default_attributes),&block)
  end

  def stamp_to(_)
    # Do Nothing
  end

  private

  def default_attributes
    {:tag=>tag,:layout_template=>self}
  end
end
