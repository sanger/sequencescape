# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class TagGroup < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :tags, ->() { order('map_id ASC') }

  scope :include_tags, ->() { includes(:tags) }

 scope :visible, -> { where(visible: true) }

  validates_presence_of :name
  validates_uniqueness_of :name

  def tags_sorted_by_map_id
    tags.sort_by(&:map_id)
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    Hash[tags.map { |tag| [tag.map_id, tag.oligo] }]
  end
end
