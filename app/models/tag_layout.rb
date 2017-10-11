# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

# Lays out the tags in the specified tag group in a particular pattern.
#
# In pulldown they use only one set of tags and put them into wells in a particular pattern: by columns, or
# by rows.  Depending on the size of the tag group that is used by the layout template it either repeats (for
# example, 8 tags in the group laid out in columns would repeat the tags across the plate), or it
# doesn't (for example, a 96 tag group would occupy an entire 96 well plate).
class TagLayout < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::TagLayout
  include Asset::Ownership::ChangesOwner

  DIRECTIONS = {
    'column'         => 'TagLayout::InColumns',
    'row'            => 'TagLayout::InRows',
    'inverse column' => 'TagLayout::InInverseColumns',
    'inverse row'    => 'TagLayout::InInverseRows'
  }.freeze

  WALKING_ALGORITHMS = {
    'wells in pools'     => 'TagLayout::WalkWellsByPools',
    'wells of plate'     => 'TagLayout::WalkWellsOfPlate',
    'manual by pool'     => 'TagLayout::WalkManualWellsByPools',
    'as group by plate'  => 'TagLayout::AsGroupByPlate',
    'manual by plate'    => 'TagLayout::WalkManualWellsOfPlate'
  }.freeze

  self.inheritance_column = 'sti_type'

  serialize :substitutions, Hash

  # The user performing the layout
  belongs_to :user, required: true
  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag_group, required: true
  belongs_to :tag2_group, class_name: 'TagGroup'
  # The plate we'll be laying out the tags into
  belongs_to :plate, required: true

  validates_presence_of :direction_algorithm
  validates_presence_of :walking_algorithm

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tags_into_wells, if: :valid?
  # After loading the record from the database, inject the behaviour.
  after_initialize :import_behaviour

  set_target_for_owner(:plate)

  def direction=(new_direction)
    self.direction_algorithm = DIRECTIONS.fetch(new_direction) { unrecognized_import!(new_direction, direction) }
    extend(direction_algorithm.constantize)
  end

  def walking_by=(walk)
    self.walking_algorithm = WALKING_ALGORITHMS.fetch(walk) { unrecognized_import!(new_direction, direction) }
    extend(walking_algorithm.constantize)
  end

  def import_behaviour
    extend(direction_algorithm.constantize) if direction_algorithm.present?
    extend(walking_algorithm.constantize)   if walking_algorithm.present?
  end

  private

  def unrecognized_import!(import, type)
    errors.add(:base, "#{import} is not a valid #{type}")
    raise(ActiveRecord::RecordInvalid, self)
  end

  def wells_in_walking_order
    @wiwo ||= plate.wells
                   .send(:"in_#{direction.tr(' ', '_')}_major_order")
                   .includes(aliquots: :tag)
  end

  # Convenience mechanism for laying out tags in a particular fashion.
  def layout_tags_into_wells
    # Make sure that the substitutions requested by the user are handled before applying the tags
    # to the wells.
    walk_wells do |well, index|
      tag_index = (index + initial_tag) % tags.length
      apply_tags(well, tags[tag_index], tag2s[tag_index])
      well.set_as_library
    end
  end

  #
  # Returns an array of tags in map order, but with any substitutions applied.
  #
  #
  # @return [Array<Tag>] An ordered array of tags
  #
  def tags
    @tags ||= ordered_tags_for(tag_group)
  end

  def tag2s
    @tag2s ||= tag2? ? ordered_tags_for(tag2_group) : []
  end

  def ordered_tags_for(tag_group)
    tag_hash = build_tag_hash(tag_group)
    tag_hash.map do |map_id, tag|
      substitutions.key?(map_id) ? tag_hash[substitutions[map_id]] : tag
    end
  end

  def build_tag_hash(tag_group)
    tag_group.tags.order(map_id: :asc).index_by { |tag| tag.map_id.to_s }
  end

  # Over-ridden in the as group by plate module to allow the application of multiple tags.
  def apply_tags(well, tag, tag2)
    well.attach_tags(tag, tag2) unless well.aliquots.empty?
  end

  def tag2?
    tag2_group.present?
  end
end
